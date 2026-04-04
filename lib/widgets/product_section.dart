import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';
import 'product_card.dart';

class ProductSection extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  final bool isHorizontal;
  final double kHorizontalPadding = 16.0;

  const ProductSection({
    super.key,
    required this.title,
    required this.products,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 8),
        isHorizontal ? _buildHorizontalList() : _buildGridList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const Row(
            children: [
              Text(
                "Xem tất cả",
                style: TextStyle(
                  color: AppColors.primaryBright,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primaryBright,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 265,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) =>
            ProductCardVertical(product: products[index], width: 160),
      ),
    );
  }

  Widget _buildGridList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding:
            EdgeInsets.zero, // THÊM: Triệt tiêu padding mặc định của GridView
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio:
              0.68, // CHỈNH: Tăng nhẹ để card cao vừa đủ, không thừa bottom
        ),
        itemCount: products.length,
        itemBuilder: (context, index) =>
            ProductCardVertical(product: products[index]),
      ),
    );
  }
}
