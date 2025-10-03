import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../Models/product_model.dart';
import '../Models/cart_model.dart';
import '../Models/cart_item_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'offline_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PosService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final OfflineService _offlineService = OfflineService.instance;
  final Cart _cart = Cart();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _lastError; // add

  // Reports (optional screens)
  Map<String, dynamic>? _salesReport;
  Map<String, dynamic>? _dailySalesReport;
  Map<String, dynamic>? _taxReport;

  // Getters expected by existing UI
  bool get isLoading => _isLoading;
  String? get lastError => _lastError; // add
  Cart get cart => _cart;

  // Some parts of UI use `catalog`, others use `products`
  List<Product> get products => List.unmodifiable(_products);
  List<Product> get catalog => List.unmodifiable(_products);

  // Passthrough totals expected on PosService by UI
  double get subtotal => _cart.subtotal;
  double get discountValue => _cart.discountValue;
  double get taxValue => _cart.taxValue;
  double get total => _cart.total;

  Map<String, dynamic>? get salesReport => _salesReport;
  Map<String, dynamic>? get dailySalesReport => _dailySalesReport;
  Map<String, dynamic>? get taxReport => _taxReport;

  // Auth
  Future<String> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
      headers: ApiConfig.getHeaders(),
      body: json.encode({'username': username, 'password': password}),
    );

    if (res.statusCode == 200) {
      final token =
          (json.decode(res.body) as Map<String, dynamic>)['access_token']
              as String;
      await _authService.saveToken(token);
      return token;
    }
    throw Exception('Login failed: ${res.body}');
  }

  // Products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _lastError = null; // reset
    notifyListeners();

    try {
      final res = await _authenticatedRequest(
        '/api/products',
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body) as List;
        _products = data
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _lastError = 'Failed to load products (${res.statusCode})';
      }
    } on Exception catch (e) {
      _lastError = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cart ops expected by UI
  void addToCart(Product product) {
    _cart.addItem(product);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void incrementQuantity(CartItem item) {
    item.quantity += 1;
    notifyListeners();
  }

  void decrementQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity -= 1;
    } else {
      _cart.removeItem(item);
    }
    notifyListeners();
  }

  Future<bool> checkout() async {
    if (cart.items.isEmpty) {
      _lastError = "Cart is empty.";
      notifyListeners();
      return false;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline =
        connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    if (!isOnline) {
      await _offlineService.queueOrder(cart.items);
      clearCart();
      _lastError = "No internet. Order queued for later.";
      notifyListeners();
      return true; // From the user's perspective, it's "successful"
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final orderPayload = {
        'items': cart.items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
      };

      final res = await _authenticatedRequest(
        '/api/orders',
        method: 'POST',
        body: orderPayload,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        clearCart(); // Also calls notifyListeners
        // Attempt to sync any pending orders after a successful online checkout
        await syncPendingOrders();
        return true;
      } else {
        _lastError = 'Checkout failed: ${res.body}';
        notifyListeners();
        return false;
      }
    } on Exception {
      // If checkout fails due to network, queue it
      await _offlineService.queueOrder(cart.items);
      clearCart();
      _lastError = 'Network error. Order queued for later.';
      notifyListeners();
      return true; // "Successful" from user's perspective
    } finally {
      _isLoading = false;
      // Final notification is handled by clearCart or the error cases
    }
  }

  Future<void> syncPendingOrders() async {
    final pendingOrders = await _offlineService.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    final connectivityResult = await (Connectivity().checkConnectivity());
    final isOnline =
        connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    if (!isOnline) return;

    for (var orderData in pendingOrders) {
      final items = (jsonDecode(orderData['items']) as List)
          .map((itemJson) => CartItem.fromJson(itemJson))
          .toList();

      final orderPayload = {
        'items': items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
      };

      try {
        final res = await _authenticatedRequest(
          '/api/orders',
          method: 'POST',
          body: orderPayload,
        );

        if (res.statusCode == 200) {
          await _offlineService.clearPendingOrder(orderData['id']);
        }
        // If it fails, we just leave it in the queue for the next sync attempt.
      } catch (_) {
        // Network error during sync, leave it for next time.
      }
    }
  }

  // Reports (only if you use reporting_screen)
  Future<void> fetchSalesReport() async {
    final res = await _authenticatedRequest('/api/reports/sales');
    if (res.statusCode == 200) {
      _salesReport = json.decode(res.body) as Map<String, dynamic>;
      notifyListeners();
      return;
    }
    throw Exception('Failed to load sales report: ${res.body}');
  }

  Future<void> fetchDailySalesReport(String date) async {
    final res = await _authenticatedRequest(
      '/api/reports/daily-sales?date_str=$date',
    );
    if (res.statusCode == 200) {
      _dailySalesReport = json.decode(res.body) as Map<String, dynamic>;
      notifyListeners();
      return;
    }
    throw Exception('Failed to load daily sales: ${res.body}');
  }

  Future<void> fetchTaxReport(String date) async {
    final res = await _authenticatedRequest('/api/reports/tax?date_str=$date');
    if (res.statusCode == 200) {
      _taxReport = json.decode(res.body) as Map<String, dynamic>;
      notifyListeners();
      return;
    }
    throw Exception('Failed to load tax report: ${res.body}');
  }

  // Internal helper
  Future<http.Response> _authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = ApiConfig.getHeaders(token);

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: json.encode(body));
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
}
