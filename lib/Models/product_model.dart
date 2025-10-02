class ProductModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    price: json['price'].toDouble(),
    stock: json['stock'],
    imageUrl: json['imageUrl'], // Backend doesn't provide, but Student A expects it
  );
}