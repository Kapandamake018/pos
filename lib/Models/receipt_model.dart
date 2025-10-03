import 'cart_item_model.dart';

class Receipt {
  final List<CartItem> items;
  final double subtotal;
  final double discountValue;
  final double taxValue;
  final double total;
  final String dateTimeString;
  Map<String, dynamic>? taxResponse; // populated when available
  Map<String, dynamic>? orderData; // original order payload for tax submission

  Receipt({
    required this.items,
    required this.subtotal,
    required this.discountValue,
    required this.taxValue,
    required this.total,
    required this.dateTimeString,
    this.taxResponse,
    this.orderData,
  });
}
