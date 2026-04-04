import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/category_model.dart';
class CategoryList extends StatefulWidget {
  final List<CategoryModel> categories;
  // 🔥 PHẢI CÓ DÒNG NÀY: Khai báo tham số nhận vào
  final Function(CategoryModel?) onCategorySelected;

  const CategoryList({
    super.key,
    required this.categories,
    required this.onCategorySelected, 
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
final remoteCategories = widget.categories.where((c) => c.id.toLowerCase() != 'all' && c.name.toLowerCase() != 'all').toList();

  final allCategories = [
    CategoryModel(id: "all", name: "Tất cả", description: ""),
    ...remoteCategories,
  ];
    return SizedBox(
      height: 46, // Chiều cao gọn gàng cho nút chữ
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });

              // 🔥 GỌI CALLBACK để báo cho HomeScreen biết đã chọn gì
              if (category.id == "all") {
                widget.onCategorySelected(null);
              } else {
                widget.onCategorySelected(category);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBright.withValues(alpha: 1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}