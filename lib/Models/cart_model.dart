import 'package:flutter/foundation.dart';
import 'cart_item_model.dart';
import 'product_model.dart';

class Cart extends ChangeNotifier {
  final List<CartItem> items = [];
  double discountPercentage = 0;
  final double taxRate = 0.16; // 16% tax rate

  // List-like helpers used by existing UI
  int get length => items.length;
  bool get isEmpty => items.isEmpty;
  CartItem operator [](int index) => items[index];

  double get subtotal => items.fold(
        0.0, // ensure double
        (sum, item) => sum + item.total,
      );

  double get discountValue => subtotal * (discountPercentage / 100);
  double get taxableAmount => subtotal - discountValue;
  double get taxValue => taxableAmount * taxRate;
  double get total => taxableAmount + taxValue;

  void addItem(Product product) {
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx == -1) {
      items.add(CartItem(product: product)); // default quantity = 1
    } else {
      items[idx].quantity += 1;
    }
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