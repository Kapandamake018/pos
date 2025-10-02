import 'package:flutter/foundation.dart';
import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;
}

class Cart extends ChangeNotifier {
  final List<CartItem> items = [];
  double discountPercentage = 0;
  final double taxRate = 0.16; // 16% tax rate

  double get subtotal => items.fold(
        0,
        (sum, item) => sum + item.total,
      );

  double get discountValue => subtotal * (discountPercentage / 100);
  double get taxableAmount => subtotal - discountValue;
  double get taxValue => taxableAmount * taxRate;
  double get total => taxableAmount + taxValue;

  void addItem(Product product) {
    final existingItem = items.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );

    if (existingItem.quantity == 0) {
      items.add(existingItem);
    }
    existingItem.quantity++;
    notifyListeners();
  }

  void removeItem(CartItem item) {
    items.remove(item);
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }
}