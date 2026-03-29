import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/member.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  Member? _selectedMember;
  double _globalDiscount = 0;

  List<CartItem> get items => _items;
  Member? get selectedMember => _selectedMember;
  double get globalDiscount => _globalDiscount;

  double get rawSubtotal => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get itemDiscount => _items.fold(0, (sum, item) => sum + (item.discount * item.quantity));
  double get memberDiscount => _globalDiscount;

  double get subtotal => rawSubtotal - itemDiscount;
  double get total => subtotal - memberDiscount;
  
  double get totalProfit => _items.fold<double>(
    0,
    (sum, item) =>
        sum + ((item.price - item.discount - (item.costPrice ?? 0)) * item.quantity),
  ) - _globalDiscount;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  void setMember(Member? member) {
    _selectedMember = member;
    notifyListeners();
  }

  void setGlobalDiscount(double discount) {
    _globalDiscount = discount;
    notifyListeners();
  }

  void addProduct(Product product) {
    var index = _items.indexWhere((item) => item.productId == product.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(
        productId: product.id,
        productName: product.name,
        price: product.price,
        discount: product.discountPrice > 0 ? (product.price - product.discountPrice) : 0,
        costPrice: product.costPrice,
        quantity: 1,
        productImagePath: product.imagePath,
        productCategory: product.category,
      ));
    }
    notifyListeners();
  }

  void updateItemDiscount(int productId, double discount) {
    var index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index].discount = discount;
      notifyListeners();
    }
  }

  void removeProduct(int id) {
    _items.removeWhere((item) => item.productId == id);
    notifyListeners();
  }

  void updateQuantity(int id, int quantity) {
    if (quantity <= 0) {
      removeProduct(id);
      return;
    }
    var index = _items.indexWhere((item) => item.productId == id);
    if (index != -1) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedMember = null;
    _globalDiscount = 0;
    notifyListeners();
  }
}
