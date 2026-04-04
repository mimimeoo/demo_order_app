import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/category_model.dart'; 

class CategoryData {
  final logger = Logger();

  Future<List<CategoryModel>> getCategories() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/files/category.json', 
      );
      final data = await json.decode(response);
      return (data['data'] as List).map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      logger.e('Lỗi khi tải danh mục đồ uống: $e'); 
      return [];
    }
  }
}