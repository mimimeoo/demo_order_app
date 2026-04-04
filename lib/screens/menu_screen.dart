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
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadMenuData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryBright));

          final categories = snapshot.data!['categories'] as List<CategoryModel>;
          final allProducts = snapshot.data!['products'] as List<ProductModel>;

          // Logic lọc sản phẩm theo Category và Tìm kiếm
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

          return Column(
            children: [
              _buildHeader(categories),
              Expanded(
                child: _buildProductGrid(filteredProducts),
              ),
            ],
          );
        },
      ),
    );
  }

  // Header: Tiêu đề -> Tìm kiếm -> Danh mục (Bỏ hoàn toàn filter phụ)
  Widget _buildHeader(List<CategoryModel> categories) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 252, 248, 245), // Màu nền nhạt bạn thích
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Thực đơn", 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Bạn muốn uống gì hôm nay?",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBright),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), 
                  borderSide: BorderSide.none
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Danh mục ngang (Category Scroller)
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBright.withValues(alpha: 1) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: isSelected ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2)
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categories[index].name,
                      style: TextStyle(
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

  // Grid hiển thị sản phẩm
  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("Không tìm thấy món bạn yêu cầu", style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Cách dưới để không bị BottomNav đè
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Điều chỉnh tỉ lệ thẻ sản phẩm cho cân đối
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCardVertical(product: products[index]);
      },
    );
  }
}