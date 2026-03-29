import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  final String remoteId; // Original String ID
  
  final String name;
  final String category;
  final double price;
  final double discountPrice; // New: discounted price if active
  final double costPrice;
  int stock;
  final String barcode;

  final String? imagePath;

  Product({
    this.id = Isar.autoIncrement,
    required this.remoteId,
    required this.name,
    required this.category,
    required this.price,
    this.discountPrice = 0,
    required this.costPrice,
    required this.stock,
    required this.barcode,
    this.imagePath,
  });

  Product copyWith({
    Id? id,
    String? remoteId,
    String? name,
    String? category,
    double? price,
    double? discountPrice,
    double? costPrice,
    int? stock,
    String? barcode,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
