import 'package:isar/isar.dart';
import 'cart_item.dart';

part 'order.g.dart';

@collection
class OrderModel {
  Id id = Isar.autoIncrement;
  
  final List<CartItem> items;
  final double total;
  final double subtotal;
  final double globalDiscount; // Added global discount field
  final int? memberId; // Added member association
  final String? memberName;
  final double cashReceived;
  final double change;
  final String paymentMethod;
  final DateTime date;
  final double totalProfit;

  OrderModel({
    this.id = Isar.autoIncrement,
    required this.items,
    required this.total,
    required this.subtotal,
    this.globalDiscount = 0,
    this.memberId,
    this.memberName,
    required this.cashReceived,
    required this.change,
    required this.paymentMethod,
    required this.date,
    required this.totalProfit,
  });
}
