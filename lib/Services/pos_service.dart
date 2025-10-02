import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../Models/product_model.dart';
import '../Models/cart_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class PosService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final Cart cart = Cart();
  List<Product> _products = [];
  Map<String, dynamic>? _salesReport;
  Map<String, dynamic>? _dailySalesReport;
  Map<String, dynamic>? _taxReport;

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  Map<String, dynamic>? get salesReport => _salesReport;
  Map<String, dynamic>? get dailySalesReport => _dailySalesReport;
  Map<String, dynamic>? get taxReport => _taxReport;

  // Original authentication methods
  Future<String> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final token = json.decode(response.body)['access_token'];
        await _authService.saveToken(token);
        return token;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Product management methods
  Future<void> fetchProducts() async {
    try {
      final response = await _authenticatedRequest('/api/products');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _products = data.map((json) => Product.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  // Cart management methods
  void addToCart(Product product) {
    cart.addItem(product);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    cart.removeItem(item);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  // Report methods
  Future<void> fetchSalesReport() async {
    final response = await _authenticatedRequest('/api/reports/sales');
    if (response.statusCode == 200) {
      _salesReport = json.decode(response.body);
      notifyListeners();
    } else {
      throw Exception('Failed to load sales report');
    }
  }

  Future<void> fetchDailySalesReport(String date) async {
    final response = await _authenticatedRequest('/api/reports/daily-sales?date_str=$date');
    if (response.statusCode == 200) {
      _dailySalesReport = json.decode(response.body);
      notifyListeners();
    } else {
      throw Exception('Failed to load daily sales report');
    }
  }

  Future<void> fetchTaxReport(String date) async {
    final response = await _authenticatedRequest('/api/reports/tax?date_str=$date');
    if (response.statusCode == 200) {
      _taxReport = json.decode(response.body);
      notifyListeners();
    } else {
      throw Exception('Failed to load tax report');
    }
  }

  // Helper method for authenticated requests
  Future<http.Response> _authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      switch (method) {
        case 'GET':
          return await http.get(uri, headers: headers);
        case 'POST':
          return await http.post(
            uri,
            headers: headers,
            body: json.encode(body),
          );
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}