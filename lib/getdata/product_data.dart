import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../models/product_model.dart';

class ProductData {
  final Logger logger = Logger();

  Future<List<ProductModel>> getProducts() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/files/product.json',
      );
      final data = json.decode(response);
      return (data['data'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      logger.e('Error loading products: $e');
      return [];
    }
  }
}
