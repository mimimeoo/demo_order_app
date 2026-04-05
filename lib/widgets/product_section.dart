import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'product_card.dart';

class ProductSection extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  final bool isHorizontal;

  const ProductSection({
    super.key,
    required this.title,
    required this.products,
    this.isHorizontal = false, 
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        if (isHorizontal)
          SizedBox(
            height: 250, // Cập nhật chiều cao
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16), 
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCardVertical(
                  width: 155, 
                  product: products[index],
                );
              },
            ),
          )
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72, // Cân đối lại tỷ lệ khung hình
              mainAxisSpacing: 12, // 🔥 KHOẢNG CÁCH DỌC GIỮA CÁC THẺ GẦN LẠI (12px)
              crossAxisSpacing: 12, // 🔥 KHOẢNG CÁCH NGANG GIỮA CÁC THẺ GẦN LẠI (12px)
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCardVertical(product: products[index]);
            },
          ),
      ],
    );
  }
}