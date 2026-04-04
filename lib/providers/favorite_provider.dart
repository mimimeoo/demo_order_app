import 'package:flutter/material.dart';
import '../models/product_model.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<ProductModel> _favorites = [];

  List<ProductModel> get favorites => _favorites;

  
  bool isExist(ProductModel product) {
    return _favorites.any((p) => p.id == product.id);
  }

  
  void toggleFavorite(ProductModel product) {
    if (isExist(product)) {
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _favorites.add(product);
    }
    notifyListeners(); 
  }
}