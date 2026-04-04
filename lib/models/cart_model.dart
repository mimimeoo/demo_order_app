import 'product_model.dart';

class CartItemModel {
  final String id; 
  final ProductModel product; 
  int quantity;
  final String selectedSize;
  final String selectedIce;
  final String selectedSweetness;
  final List<String> selectedToppings;
  final String note;
  final double itemPrice; 
  CartItemModel({
    required this.id,
    required this.product,
    this.quantity = 1,
    required this.selectedSize,
    required this.selectedIce,
    required this.selectedSweetness,
    required this.selectedToppings,
    this.note = '',
    required this.itemPrice,
  });
}