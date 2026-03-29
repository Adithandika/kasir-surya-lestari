import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/database_service.dart';

class ReportsProvider with ChangeNotifier {
  List<OrderModel> _allOrders = [];
  
  List<OrderModel> get allOrders => _allOrders;

  ReportsProvider() {
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    _allOrders = await DatabaseService.getOrderHistory();
    notifyListeners();
  }

  // Filtered Lists
  List<OrderModel> get weeklyOrders {
    final now = DateTime.now();
    // Inclusive filter: start of the day 7 days ago
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    return _allOrders.where((o) => o.date.isAfter(sevenDaysAgo) || o.date.isAtSameMomentAs(sevenDaysAgo)).toList();
  }

  List<OrderModel> get monthlyOrders {
    final now = DateTime.now();
    // Inclusive: start of the day thirty days ago
    final thirtyDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    return _allOrders.where((o) => o.date.isAfter(thirtyDaysAgo) || o.date.isAtSameMomentAs(thirtyDaysAgo)).toList();
  }

  List<OrderModel> get yearlyOrders {
    final now = DateTime.now();
    // One year ago from today
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    return _allOrders.where((o) => o.date.isAfter(oneYearAgo) || o.date.isAtSameMomentAs(oneYearAgo)).toList();
  }

  // Statistics Calculation
  double calculateTotalSales(List<OrderModel> orders) =>
      orders.fold(0, (sum, o) => sum + o.total);

  double calculateTotalProfit(List<OrderModel> orders) =>
      orders.fold(0, (sum, o) => sum + o.totalProfit);

  int calculateTotalTransactions(List<OrderModel> orders) => orders.length;

  double calculateAverageTransaction(List<OrderModel> orders) {
    if (orders.isEmpty) return 0;
    return calculateTotalSales(orders) / orders.length;
  }

  // Data for Charts
  Map<DateTime, double> getDailySales(List<OrderModel> orders) {
    final Map<DateTime, double> data = {};
    for (var order in orders) {
      final date = DateTime(order.date.year, order.date.month, order.date.day);
      data[date] = (data[date] ?? 0) + order.total;
    }
    return data;
  }

  Map<int, double> getMonthlySales(List<OrderModel> orders) {
    final Map<int, double> data = {};
    for (var order in orders) {
      data[order.date.month] = (data[order.date.month] ?? 0) + order.total;
    }
    return data;
  }

  Map<String, int> getTopProducts(List<OrderModel> orders, {int limit = 5}) {
    final Map<String, int> productCounts = {};
    for (var order in orders) {
      for (var item in order.items) {
        final name = item.productName ?? 'Unknown';
        productCounts[name] = (productCounts[name] ?? 0) + item.quantity;
      }
    }
    final sorted = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  Map<String, double> getCategoryDistribution(List<OrderModel> orders) {
    final Map<String, double> categorySales = {};
    for (var order in orders) {
      for (var item in order.items) {
        final category = item.productCategory ?? 'Lainnya';
        categorySales[category] = (categorySales[category] ?? 0) + item.subtotal;
      }
    }
    return categorySales;
  }
  
  Future<void> refresh() async {
    await _loadAllOrders();
  }
}
