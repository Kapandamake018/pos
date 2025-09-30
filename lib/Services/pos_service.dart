// lib/services/pos_service.dart

import 'package:flutter/material.dart';
import '../Models/product_model.dart';
import '../Models/cart_item_model.dart';

class PosService extends ChangeNotifier {
  // --- Product Listing ---
  final List<Product> _catalog = [
    // Sample Data
    Product(id: '1', name: 'Classic Burger', description: 'A juicy beef patty with fresh vegetables.', price: 8.99, imageUrl: 'https://via.placeholder.com/150'),
    Product(id: '2', name: 'Fries', description: 'Crispy golden fries.', price: 3.49, imageUrl: 'https://via.placeholder.com/150'),
    Product(id: '3', name: 'Soda', description: 'Refreshing carbonated drink.', price: 1.99, imageUrl: 'https://via.placeholder.com/150'),
    Product(id: '4', name: 'Cheese Pizza', description: 'Classic cheese pizza with a thin crust.', price: 12.50, imageUrl: 'https://via.placeholder.com/150'),
    Product(id: '5', name: 'Caesar Salad', description: 'Fresh romaine lettuce with Caesar dressing.', price: 7.00, imageUrl: 'https://via.placeholder.com/150'),
  ];

  List<Product> get catalog => _catalog;

  // --- Cart Management ---
  final List<CartItem> _cart = [];
  List<CartItem> get cart => _cart;

  void addToCart(Product product) {
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

  // --- Tax and Discount Calculations ---
  final double _taxRate = 0.08; // 8% tax
  final double _discountPercentage = 0.10; // 10% discount

  double get subtotal => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  // Example: Discount is applied on the subtotal
  double get discountValue => subtotal * _discountPercentage;

  double get subtotalAfterDiscount => subtotal - discountValue;

  // Example: Tax is calculated on the subtotal after discount
  double get taxValue => subtotalAfterDiscount * _taxRate;

  double get total => subtotalAfterDiscount + taxValue;
}
