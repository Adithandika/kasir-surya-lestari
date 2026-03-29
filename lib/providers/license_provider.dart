import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LicenseProvider with ChangeNotifier {
  static const String _keyTotalCommission = 'license_total_commission';
  static const String _keyUnpaidCommission = 'license_unpaid_commission';
  static const String _keyLastCheckedMonth = 'license_last_checked_month';
  static const String _keyIsPaid = 'license_is_paid_for_last_month';

  double _totalCommission = 0;
  double _unpaidCommission = 0;
  String _lastCheckedMonth = '';
  bool _isPaidForLastMonth = true;
  bool _initialized = false;

  double get totalCommission => _totalCommission;
  double get unpaidCommission => _unpaidCommission;
  bool get isPaidForLastMonth => _isPaidForLastMonth;
  bool get isInitialized => _initialized;

  LicenseProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _totalCommission = prefs.getDouble(_keyTotalCommission) ?? 0;
    _unpaidCommission = prefs.getDouble(_keyUnpaidCommission) ?? 0;
    _lastCheckedMonth = prefs.getString(_keyLastCheckedMonth) ?? '';
    _isPaidForLastMonth = prefs.getBool(_keyIsPaid) ?? true;

    _checkMonthTransition();
    _initialized = true;
    notifyListeners();
  }

  void _checkMonthTransition() {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    
    if (_lastCheckedMonth.isNotEmpty && _lastCheckedMonth != currentMonth) {
      // Month has changed!
      // If there was unpaid commission from previous month, user is now "unpaid"
      if (_unpaidCommission > 0) {
        _isPaidForLastMonth = false;
      }
      // Note: We don't reset _unpaidCommission here because it's now the "Debt" 
      // from last month that must be paid.
    }
    
    _lastCheckedMonth = currentMonth;
    _saveData();
  }

  bool get isBlocked {
    if (!_initialized) return false;
    
    // Block if:
    // 1. Month has changed since last activity AND there was unpaid commission
    // 2. _isPaidForLastMonth is false
    return !_isPaidForLastMonth;
  }

  Future<void> addCommission(double orderTotal) async {
    final commission = orderTotal * 0.007;
    _totalCommission += commission;
    _unpaidCommission += commission;
    
    // Ensure we are in the correct month context
    _checkMonthTransition();
    
    await _saveData();
    notifyListeners();
  }

  Future<void> markAsPaid() async {
    _unpaidCommission = 0;
    _isPaidForLastMonth = true;
    await _saveData();
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTotalCommission, _totalCommission);
    await prefs.setDouble(_keyUnpaidCommission, _unpaidCommission);
    await prefs.setString(_keyLastCheckedMonth, _lastCheckedMonth);
    await prefs.setBool(_keyIsPaid, _isPaidForLastMonth);
  }
}
