import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:logger/logger.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

class DataService {
  static final Logger logger = Logger();
  static Future<List<CategoryModel>> loadCategories() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/files/category.json',
      );
      
      // SỬA Ở ĐÂY: Nhận dữ liệu dưới dạng Map (Object) thay vì List
      final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
      
      // SAU ĐÓ: Trích xuất mảng bên trong key 'data'
      final List<dynamic> dataList = jsonResponse['data'];
      
      return dataList.map((data) => CategoryModel.fromJson(data)).toList();
    } catch (e) {
      logger.e("Lỗi khi đọc category.json: $e");
      return [];
    }
  }
  static Future<List<ProductModel>> loadProducts() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/files/product.json',
      );
      final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
      final List<dynamic> dataList = jsonResponse['data'];
      return dataList.map((data) => ProductModel.fromJson(data)).toList();
    } catch (e) {
      logger.e("Lỗi khi đọc product.json: $e");
      return [];
    }
  }
}