import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'primary_color';
  static const String _shopNameKey = 'shop_name';
  static const String _posCartWidthKey = 'pos_cart_width';
  static const String _printerIpKey = 'printer_ip';
  static const String _printerPortKey = 'printer_port';
  static const String _printerPaperSizeKey = 'printer_paper_size';

  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(0xFF0EA5E9); // Sky blue instead of Indigo
  String _shopName = 'Cashierya App';
  double _posCartWidth = 320.0;
  String _printerIp = '192.168.1.100';
  int _printerPort = 9100;
  String _printerPaperSize = '80mm';
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  String get shopName => _shopName;
  double get posCartWidth => _posCartWidth;
  String get printerIp => _printerIp;
  int get printerPort => _printerPort;
  String get printerPaperSize => _printerPaperSize;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final mode = prefs.getString(_themeKey);
      final colorHex = prefs.getString(_colorKey);
      final shopName = prefs.getString(_shopNameKey);
      final cartWidth = prefs.getDouble(_posCartWidthKey);
      
      if (mode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (mode == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }

      if (colorHex != null) {
        _primaryColor = Color(int.parse(colorHex, radix: 16));
      }
      _shopName = shopName ?? 'Cashierya App';
      _posCartWidth = (cartWidth ?? 320.0).clamp(280.0, 800.0);
      _printerIp = prefs.getString(_printerIpKey) ?? '192.168.1.100';
      _printerPort = prefs.getInt(_printerPortKey) ?? 9100;
      _printerPaperSize = prefs.getString(_printerPaperSizeKey) ?? '80mm';
    } catch (e) {
      debugPrint('ThemeProvider: Failed to load settings: $e');
      // Fallback to default values already set
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      debugPrint('ThemeProvider: Failed to save theme mode: $e');
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_colorKey, color.toARGB32().toRadixString(16));
    } catch (e) {
      debugPrint('ThemeProvider: Failed to save primary color: $e');
    }
  }

  Future<void> setShopName(String name) async {
    _shopName = name;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_shopNameKey, name);
    } catch (e) {
      debugPrint('ThemeProvider: Failed to save shop name: $e');
    }
  }

  Future<void> setPosCartWidth(double width) async {
    _posCartWidth = width.clamp(280.0, 800.0);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_posCartWidthKey, _posCartWidth);
    } catch (e) {
      debugPrint('ThemeProvider: Failed to save cart width: $e');
    }
  }

  Future<void> setPrinterIp(String ip) async {
    _printerIp = ip;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_printerIpKey, ip);
    } catch (e) {
      debugPrint('ThemeProvider: Failed to save printer IP: $e');
    }
  }

  Future<void> setPrinterPort(int port) async {
    _printerPort = port;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_printerPortKey, port);
    } catch (e) {
      debugPrint('ThemeProvider: Failed to save printer port: $e');
    }
  }

  Future<void> setPrinterPaperSize(String size) async {
    _printerPaperSize = size;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_printerPaperSizeKey, size);
    } catch (e) {
      debugPrint('ThemeProvider: Failed to save printer paper size: $e');
    }
  }
}
