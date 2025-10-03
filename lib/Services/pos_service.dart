import 'dart:convert';
import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../Models/product_model.dart';
import '../Models/cart_model.dart';
import '../Models/cart_item_model.dart';
import '../Models/receipt_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'offline_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'tax_service.dart';

class PosService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final OfflineService _offlineService = OfflineService.instance;
  final TaxService _taxService = TaxService();
  final Cart _cart = Cart();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _lastError; // add

  // Reports (optional screens)
  Map<String, dynamic>? _salesReport;
  Map<String, dynamic>? _dailySalesReport;
  Map<String, dynamic>? _taxReport;
  Receipt? _lastReceipt;

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
  double get discountPercentage => _cart.discountPercentage;

  Map<String, dynamic>? get salesReport => _salesReport;
  Map<String, dynamic>? get dailySalesReport => _dailySalesReport;
  Map<String, dynamic>? get taxReport => _taxReport;
  Receipt? get lastReceipt => _lastReceipt;

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

      if (res.statusCode >= 200 && res.statusCode < 300) {
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

  void setDiscountPercentage(double percent) {
    // Clamp between 0 and 100
    if (percent.isNaN || !percent.isFinite) return;
    final clamped = percent.clamp(0, 100).toDouble();
    _cart.discountPercentage = clamped;
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

      // Accept any 2xx status as success (some backends return 201/204)
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Snapshot current cart to build a receipt before clearing
        _lastReceipt = Receipt(
          items: List.from(
            cart.items.map((e) => CartItem.fromJson(e.toJson())),
          ),
          subtotal: subtotal,
          discountValue: discountValue,
          taxValue: taxValue,
          total: total,
          dateTimeString: DateTime.now().toIso8601String(),
          orderData: orderPayload,
        );
        // Submit the invoice to the tax authority without blocking checkout
        try {
          final orderDetails = json.decode(res.body) as Map<String, dynamic>;
          unawaited(
            _taxService
                .submitInvoice(orderDetails)
                .timeout(const Duration(seconds: 5))
                .then(
                  (resp) {
                    // Save authority response onto receipt if present
                    if (_lastReceipt != null) {
                      _lastReceipt!.taxResponse = resp;
                      notifyListeners();
                    }
                    // Fire-and-forget logging of the tax response to backend
                    try {
                      final cis =
                          resp['cis_invc_no'] ??
                          resp['cisInvcNo'] ??
                          resp['invoice_number'];
                      unawaited(
                        _authenticatedRequest(
                          '/api/invoices/log',
                          method: 'POST',
                          body: {
                            if (cis != null) 'cis_invc_no': cis,
                            'response': resp,
                          },
                        ).then((_) {}, onError: (_) {}),
                      );
                    } catch (_) {}
                  },
                  onError: (e) {
                    if (kDebugMode) {
                      print('Failed to submit invoice to tax authority: $e');
                    }
                    // Surface the error on the receipt so UI does not stay in 'Submitting...'
                    if (_lastReceipt != null) {
                      _lastReceipt!.taxResponse = {
                        'status': 'failed',
                        'message': e.toString(),
                      };
                      notifyListeners();
                    }
                  },
                ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Failed to parse order details for tax submission: $e');
          }
        }

        clearCart(); // Also calls notifyListeners
        // Fire-and-forget sync of any pending orders as well
        unawaited(syncPendingOrders());
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
      // Make sure UI stops showing the global loading spinner
      notifyListeners();
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

        if (res.statusCode >= 200 && res.statusCode < 300) {
          await _offlineService.clearPendingOrder(orderData['id']);
        }
        // If it fails, we just leave it in the queue for the next sync attempt.
      } catch (_) {
        // Network error during sync, leave it for next time.
      }
    }
  }

  // UI helpers for pending orders screen
  Future<List<Map<String, dynamic>>> getPendingOrdersUI() async {
    return _offlineService.getPendingOrders();
  }

  Future<void> retryPendingNow() async {
    await syncPendingOrders();
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

  // Manual resubmission of invoice to tax authority from Receipt screen
  Future<void> resubmitTax(Map<String, dynamic> orderData) async {
    try {
      final resp = await _taxService
          .submitInvoice(orderData)
          .timeout(const Duration(seconds: 5));
      if (_lastReceipt != null) {
        _lastReceipt!.taxResponse = resp;
        notifyListeners();
      }
      // Also log to backend
      try {
        final cis =
            resp['cis_invc_no'] ?? resp['cisInvcNo'] ?? resp['invoice_number'];
        unawaited(
          _authenticatedRequest(
            '/api/invoices/log',
            method: 'POST',
            body: {if (cis != null) 'cis_invc_no': cis, 'response': resp},
          ).then((_) {}, onError: (_) {}),
        );
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }

  // Logout: clear saved token and reset local session state
  Future<void> logout() async {
    await _authService.deleteToken();
    _products = [];
    _cart.clear();
    _lastReceipt = null;
    _lastError = null;
    _salesReport = null;
    _dailySalesReport = null;
    _taxReport = null;
    notifyListeners();
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
