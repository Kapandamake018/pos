import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Models/product_model.dart';
import '../Models/cart_item_model.dart';

class PosService extends ChangeNotifier {
  // --- Backend Integration ---
  String? _accessToken;
  Map<String, dynamic>? _salesReport;
  Map<String, dynamic>? _dailySalesReport;
  Map<String, dynamic>? _taxReport;
  List<ProductModel> _products = [];
  final String _baseUrl = 'http://192.168.30.28';  // Emulator alias for localhost

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get salesReport => _salesReport;
  Map<String, dynamic>? get dailySalesReport => _dailySalesReport;
  Map<String, dynamic>? get taxReport => _taxReport;
  List<ProductModel> get catalog => _products;

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      _accessToken = jsonDecode(response.body)['access_token'];
      notifyListeners();
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/products'));
    if (response.statusCode == 200) {
      _products = (jsonDecode(response.body) as List)
          .map((data) => ProductModel.fromJson(data))
          .toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<void> fetchSalesReport() async {
    if (_accessToken == null) await login('admin', 'password');
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/sales'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      _salesReport = jsonDecode(response.body);
      notifyListeners();
    } else {
      throw Exception('Failed to load sales report: ${response.statusCode}');
    }
  }

  Future<void> fetchDailySalesReport(String date) async {
    if (_accessToken == null) await login('admin', 'password');
    final response = await http.get(
      Uri.parse('$_baseUrl/api/reports/daily-sales?date_str=$date'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      _dailySalesReport = jsonDecode(response.body);
      notifyListeners();
    } else {
      throw Exception('Failed to load daily sales report: ${response.statusCode}');
    }
  }

  Future<void> fetchTaxReport(String date) async {
    if (_accessToken == null) await login('admin', 'password');
    final response = await http.get(
      Uri.parse('$_baseUrl/api/reports/tax?date_str=$date'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      _taxReport = jsonDecode(response.body);
      notifyListeners();
    } else {
      throw Exception('Failed to load tax report: ${response.statusCode}');
    }
  }

  // --- Cart Management (Student A's Logic) ---
  final List<CartItem> _cart = [];
  List<CartItem> get cart => _cart;

  void addToCart(ProductModel product) {
    for (var item in _cart) {
      if (item.product.id == product.id) {
        item.quantity++;
        notifyListeners();
        return;
      }
    }
    _cart.add(CartItem(product: product));
    notifyListeners();
  }

  void removeFromCart(CartItem cartItem) {
    _cart.remove(cartItem);
    notifyListeners();
  }

  void incrementQuantity(CartItem cartItem) {
    cartItem.quantity++;
    notifyListeners();
  }

  void decrementQuantity(CartItem cartItem) {
    if (cartItem.quantity > 1) {
      cartItem.quantity--;
    } else {
      removeFromCart(cartItem);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // --- Tax and Discount Calculations (Student A's Logic) ---
  final double _taxRate = 0.08; // 8% tax (note: backend uses 16% VAT)
  final double _discountPercentage = 0.10; // 10% discount

  double get subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  double get discountValue => subtotal * _discountPercentage;

  double get subtotalAfterDiscount => subtotal - discountValue;

  double get taxValue => subtotalAfterDiscount * _taxRate;

  double get total => subtotalAfterDiscount + taxValue;
}