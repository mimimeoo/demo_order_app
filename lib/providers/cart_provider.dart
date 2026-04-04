import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.itemPrice * cartItem.quantity;
    });
    return total;
  }
  String get formattedTotal {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(totalAmount)}đ";
  }

  void addItem(CartItemModel item) {
    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity += item.quantity;
    } else {
      _items[item.id] = item;
    }
    notifyListeners();
  }

  void increaseQuantity(String id) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
      notifyListeners();
    }
  }

 
  void decreaseQuantity(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity > 1) {
      _items[id]!.quantity--;
      notifyListeners();
    }
  }

  
  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}