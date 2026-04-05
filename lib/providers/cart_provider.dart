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

  // 🔥 THÊM LOGIC KIỂM TRA: 2 sản phẩm có cấu hình giống y hệt nhau không
  bool _isSameItem(CartItemModel a, CartItemModel b) {
    if (a.product.id != b.product.id) return false;
    if (a.selectedSize != b.selectedSize) return false;
    if (a.selectedIce != b.selectedIce) return false;
    if (a.selectedSweetness != b.selectedSweetness) return false;
    if (a.note != b.note) return false;
    
    // Kiểm tra danh sách topping
    if (a.selectedToppings.length != b.selectedToppings.length) return false;
    var aToppings = List.from(a.selectedToppings)..sort();
    var bToppings = List.from(b.selectedToppings)..sort();
    for (int i = 0; i < aToppings.length; i++) {
      if (aToppings[i] != bToppings[i]) return false;
    }
    return true;
  }

  void addItem(CartItemModel item) {
    String? existingKey;
    
    // Tìm xem trong giỏ đã có món nào giống y hệt cấu hình chưa
    _items.forEach((key, existingItem) {
      if (key != item.id && _isSameItem(existingItem, item)) {
        existingKey = key;
      }
    });

    if (existingKey != null) {
      // Nếu có món y hệt, gộp số lượng lại cho gọn giỏ hàng
      _items[existingKey!]!.quantity += item.quantity;
    } else {
      // Nếu không, thêm mới (hoặc ghi đè lưu lại item đang Edit)
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