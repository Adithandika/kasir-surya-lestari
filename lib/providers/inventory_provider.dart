import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class InventoryProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _customCategories = [];
  String _sortBy = 'Name (A-Z)';

  List<String> get categories => ['All', ..._customCategories];

  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  List<Product> get products => _filteredProducts;

  InventoryProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _customCategories = prefs.getStringList('inventory_categories') ?? [
      'Sembako',
      'Minuman',
      'Snack',
      'Bumbu',
      'Kebersihan',
    ];

    _products = await DatabaseService.getAllProducts();
    if (_products.isEmpty) {
      await _seedSampleData();
      _products = await DatabaseService.getAllProducts();
    }
    _applyFilters();
  }

  Future<void> _seedSampleData() async {
    final sampleData = [
      Product(
        remoteId: '1',
        name: 'Beras Setra Ramos 5Kg',
        category: 'Sembako',
        price: 75000,
        costPrice: 70000,
        stock: 20,
        barcode: '899123456781',
      ),
      Product(
        remoteId: '2',
        name: 'Minyak Goreng Bimoli 2L',
        category: 'Sembako',
        price: 38000,
        costPrice: 35000,
        stock: 15,
        barcode: '899123456782',
      ),
      Product(
        remoteId: '3',
        name: 'Gula Pasir Gulaku 1Kg',
        category: 'Sembako',
        price: 16000,
        costPrice: 14500,
        stock: 3,
        barcode: '899123456783',
      ),
      Product(
        remoteId: '4',
        name: 'Indomie Goreng',
        category: 'Sembako',
        price: 3000,
        costPrice: 2500,
        stock: 100,
        barcode: '899123456784',
      ),
      Product(
        remoteId: '5',
        name: 'Aqua Botol 600ml',
        category: 'Minuman',
        price: 3500,
        costPrice: 2500,
        stock: 48,
        barcode: '899123456785',
      ),
      Product(
        remoteId: '6',
        name: 'Teh Pucuk Harum 350ml',
        category: 'Minuman',
        price: 4000,
        costPrice: 3000,
        stock: 2,
        barcode: '899123456786',
      ),
      Product(
        remoteId: '7',
        name: 'Chitato Sapi Panggang',
        category: 'Snack',
        price: 10000,
        costPrice: 8500,
        stock: 25,
        barcode: '899123456787',
      ),
      Product(
        remoteId: '8',
        name: 'Taro Net Seaweed',
        category: 'Snack',
        price: 5000,
        costPrice: 4000,
        stock: 30,
        barcode: '899123456788',
      ),
      Product(
        remoteId: '9',
        name: 'Kecap Bango 520ml',
        category: 'Bumbu',
        price: 25000,
        costPrice: 22000,
        stock: 10,
        barcode: '899123456789',
      ),
      Product(
        remoteId: '10',
        name: 'Rinso Anti Noda 700g',
        category: 'Kebersihan',
        price: 22000,
        costPrice: 19000,
        stock: 4,
        barcode: '899123456790',
      ),
      Product(
        remoteId: '11',
        name: 'Sunlight Jeruk Nipis',
        category: 'Kebersihan',
        price: 15000,
        costPrice: 13000,
        stock: 15,
        barcode: '899123456791',
      ),
      Product(
        remoteId: '12',
        name: 'Telur Ayam 1Kg',
        category: 'Sembako',
        price: 28000,
        costPrice: 26000,
        stock: 10,
        barcode: '899123456792',
      ),
    ];
    for (var p in sampleData) {
      await DatabaseService.saveProduct(p);
    }
  }

  void searchProduct(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setSortBy(String value) {
    _sortBy = value;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery) ||
          p.barcode.contains(_searchQuery);
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Apply Sorting
    switch (_sortBy) {
      case 'Name (A-Z)':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name (Z-A)':
        _filteredProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Price (Low-High)':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price (High-Low)':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Stock (Low-High)':
        _filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'Stock (High-Low)':
        _filteredProducts.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }

    notifyListeners();
  }

  int getProductCountByCategory(String category) {
    return _products.where((p) => p.category == category).length;
  }

  Product? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  Future<void> reduceStock(int id, int quantity) async {
    var index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index].stock -= quantity;
      if (_products[index].stock < 0) {
        _products[index].stock = 0;
      }
      await DatabaseService.saveProduct(_products[index]);
      _applyFilters();
    }
  }

  Future<void> addStock(int id, int quantity) async {
    var index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index].stock += quantity;
      await DatabaseService.saveProduct(_products[index]);
      _applyFilters();
    }
  }

  Future<void> addProduct(Product product) async {
    await DatabaseService.saveProduct(product);
    _products = await DatabaseService.getAllProducts();
    _applyFilters();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    await DatabaseService.saveProduct(updatedProduct);
    _products = await DatabaseService.getAllProducts();
    _applyFilters();
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseService.deleteProduct(id);
    _products = await DatabaseService.getAllProducts();
    _applyFilters();
  }

  Future<void> addCategory(String category) async {
    final name = category.trim();
    if (name.isNotEmpty && !_customCategories.contains(name)) {
      _customCategories.add(name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('inventory_categories', _customCategories);
      notifyListeners();
    }
  }

  Future<void> removeCategory(String category) async {
    if (_customCategories.contains(category)) {
      _customCategories.remove(category);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('inventory_categories', _customCategories);
      
      if (_selectedCategory == category) {
        _selectedCategory = 'All';
      }
      _applyFilters();
    }
  }
}
