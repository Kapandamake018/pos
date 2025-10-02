// lib/models/cart_item_model.dart

import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
  }) : quantity = 1;

  double get total => product.price * quantity;
}