import 'package:isar/isar.dart';

part 'cart_item.g.dart';

@embedded
class CartItem {
  int? productId;
  String? productName;
  double price;
  double discount; // Added discount per item
  double? costPrice;
  int quantity;
  String? productImagePath;
  String? productCategory;

  CartItem({
    this.productId,
    this.productName,
    this.price = 0,
    this.discount = 0,
    this.costPrice = 0,
    this.quantity = 1,
    this.productImagePath,
    this.productCategory,
  });

  double get subtotal => (price - discount) * quantity;
}
