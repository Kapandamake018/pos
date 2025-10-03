// lib/models/cart_item_model.dart

import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product}) : quantity = 1;

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {'product': product.toJson(), 'quantity': quantity};
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(product: Product.fromJson(json['product']))
      ..quantity = json['quantity'];
  }
}
