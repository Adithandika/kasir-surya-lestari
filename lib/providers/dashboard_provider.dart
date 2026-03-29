import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/database_service.dart';

class DashboardProvider with ChangeNotifier {
  List<OrderModel> _history = [];

  List<OrderModel> get history => _history;

  double get totalSales => _history.fold(0, (sum, order) => sum + order.total);
  double get totalProfit =>
      _history.fold(0, (sum, order) => sum + order.totalProfit);
  int get totalTransactions => _history.length;

  String get topSellingProduct {
    if (_history.isEmpty) return 'Belum ada data';
    final productSales = <String, int>{};
    for (var order in _history) {
      for (var item in order.items) {
        final name = item.productName ?? 'Tanpa Nama';
        productSales[name] = (productSales[name] ?? 0) + item.quantity;
      }
    }
    if (productSales.isEmpty) return 'Belum ada data';
    var topProduct = '';
    var maxQty = 0;
    productSales.forEach((name, qty) {
      if (qty > maxQty) {
        maxQty = qty;
        topProduct = name;
      }
    });
    return topProduct;
  }

  double get memberTransactionPercentage {
    if (_history.isEmpty) return 0;
    final memberOrders = _history.where((o) => o.memberId != null).length;
    return (memberOrders / _history.length) * 100;
  }

  double get averageTransactionValue {
    if (_history.isEmpty) return 0;
    return totalSales / _history.length;
  }

  String get busiestHour {
    if (_history.isEmpty) return 'Belum ada data';
    final hourCounts = <int, int>{};
    for (var order in _history) {
      hourCounts[order.date.hour] = (hourCounts[order.date.hour] ?? 0) + 1;
    }
    if (hourCounts.isEmpty) return 'Belum ada data';
    
    var topHour = 0;
    var maxCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        topHour = hour;
      }
    });
    
    final formattedStart = topHour.toString().padLeft(2, '0');
    final formattedEnd = (topHour + 1).toString().padLeft(2, '0');
    return '$formattedStart:00 - $formattedEnd:00';
  }

  String get topCategory {
    if (_history.isEmpty) return 'Belum ada data';
    final categorySales = <String, int>{};
    for (var order in _history) {
      for (var item in order.items) {
        final category = item.productCategory ?? 'Tanpa Kategori';
        categorySales[category] = (categorySales[category] ?? 0) + item.quantity;
      }
    }
    if (categorySales.isEmpty) return 'Belum ada data';
    
    var topCategoryName = '';
    var maxQty = 0;
    categorySales.forEach((category, qty) {
      if (qty > maxQty) {
        maxQty = qty;
        topCategoryName = category;
      }
    });
    return topCategoryName;
  }

  double get profitMarginPercentage {
    if (totalSales == 0) return 0;
    return (totalProfit / totalSales) * 100;
  }

  String get slowestMovingProduct {
    if (_history.isEmpty) return 'Belum ada data';
    final productSales = <String, int>{};
    for (var order in _history) {
      for (var item in order.items) {
        final name = item.productName ?? 'Tanpa Nama';
        productSales[name] = (productSales[name] ?? 0) + item.quantity;
      }
    }
    if (productSales.isEmpty) return 'Belum ada data';
    
    var slowestProduct = '';
    var minQty = 999999;
    productSales.forEach((name, qty) {
      if (qty < minQty) {
        minQty = qty;
        slowestProduct = name;
      }
    });
    return slowestProduct;
  }

  String get suggestedBundle {
    if (_history.isEmpty || _history.length < 3) return 'Data transaksi masih kurang';
    
    // For a simple bundle suggestion, we pair the top selling product 
    // with a randomly selected other product or the slowest moving product.
    final topProduct = topSellingProduct;
    final slowestProduct = slowestMovingProduct;
    
    if (topProduct == 'Belum ada data' || slowestProduct == 'Belum ada data' || topProduct == slowestProduct) {
      return 'Belum ada kombinasi yang cocok';
    }
    
    return '$topProduct + $slowestProduct';
  }

  String get peakDayOfWeek {
    if (_history.isEmpty) return 'Belum ada data';
    
    final dayCounts = <int, int>{}; // 1 = Mon, 7 = Sun
    for (var order in _history) {
      dayCounts[order.date.weekday] = (dayCounts[order.date.weekday] ?? 0) + 1;
    }
    
    if (dayCounts.isEmpty) return 'Belum ada data';
    
    var topDayStr = '';
    var maxCount = 0;
    var topDayInt = 1;
    
    dayCounts.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        topDayInt = day;
      }
    });
    
    switch (topDayInt) {
      case 1: topDayStr = 'Senin'; break;
      case 2: topDayStr = 'Selasa'; break;
      case 3: topDayStr = 'Rabu'; break;
      case 4: topDayStr = 'Kamis'; break;
      case 5: topDayStr = 'Jum\'at'; break;
      case 6: topDayStr = 'Sabtu'; break;
      case 7: topDayStr = 'Minggu'; break;
      default: topDayStr = 'Belum ada data';
    }
    
    return topDayStr;
  }

  DashboardProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _history = await DatabaseService.getOrderHistory();
    notifyListeners();
  }

  Future<void> addOrder(OrderModel order) async {
    await DatabaseService.saveOrder(order);
    _history = await DatabaseService.getOrderHistory();
    notifyListeners();
  }
}
