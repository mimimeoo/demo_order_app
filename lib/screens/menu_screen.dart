import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart'; 

import '../widgets/product_card.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

// Hàm hỗ trợ bỏ dấu tiếng Việt để tìm kiếm chính xác
String removeVietnameseTones(String str) {
  str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');
  str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
  str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
  str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
  str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
  str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
  str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
  str = str.replaceAll(RegExp(r'[Đ]'), 'D');
  return str.toLowerCase();
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedCategoryIndex = 0; 
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> loadMenuData() async {
    try {
      final db = FirebaseFirestore.instance;

      final categorySnapshot = await db.collection('categories').get();
      final categories = categorySnapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList();

      final productSnapshot = await db.collection('products').get();
      final products = productSnapshot.docs.map((doc) => ProductModel.fromJson(doc.data())).toList();

      // Sắp xếp danh mục và thêm nút mặc định
      categories.sort((a, b) => a.id.compareTo(b.id));
      if (!categories.any((c) => c.id == 'all')) {
        categories.insert(0, CategoryModel(id: 'all', name: 'Tất cả', description: ''));
      }

      return {'categories': categories, 'products': products};
    } catch (e) {
      throw Exception("Lỗi tải thực đơn: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Đổi toàn bộ màu nền thành màu trắng
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadMenuData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

          final categories = snapshot.data!['categories'] as List<CategoryModel>;
          final allProducts = snapshot.data!['products'] as List<ProductModel>;

          // Logic lọc sản phẩm theo Category và Tìm kiếm (Giữ nguyên)
          List<ProductModel> filteredProducts = [];
          if (_searchQuery.isNotEmpty) {
            filteredProducts = allProducts.where((p) {
              final nameNormal = removeVietnameseTones(p.name);
              final queryNormal = removeVietnameseTones(_searchQuery);
              return nameNormal.contains(queryNormal);
            }).toList();
          } else {
            final displayCategory = categories[_selectedCategoryIndex];
            filteredProducts = displayCategory.id == 'all' 
                ? allProducts 
                : allProducts.where((p) => p.categoryId == displayCategory.id).toList();
          }

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(categories),
                Expanded(
                  child: _buildProductGrid(filteredProducts),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // === HEADER ===
  Widget _buildHeader(List<CategoryModel> categories) {
    return Container(
      color: Colors.white, // Nền phần Header cũng là màu trắng
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề lớn
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Thực đơn", 
              style: TextStyle(fontFamily: 'GoogleSans', fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)
            ),
          ),
          const SizedBox(height: 16),
          
          // === THANH TÌM KIẾM ĐỒNG BỘ 100% VỚI HOME ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26), // Bo tròn thành hình viên thuốc
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm đồ uống...",
                        hintStyle: TextStyle(fontFamily: 'GoogleSans', color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14), // Giúp text canh giữa theo chiều dọc
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade200), // Vạch ngăn cách
                  IconButton(
                    icon: const Icon(
                      Icons.tune_rounded, // Icon bộ lọc (Filter)
                      color: AppColors.primary,
                      size: 22,
                    ),
                    onPressed: () {},
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Danh mục ngang (Pill Tabs)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), 
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categories[index].name,
                      style: TextStyle(
                        fontFamily: 'GoogleSans',
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // === GRID SẢN PHẨM ===
  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "Không tìm thấy món bạn yêu cầu", 
              style: TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.grey.shade500)
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72, 
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCardVertical(product: products[index]);
      },
    );
  }
}