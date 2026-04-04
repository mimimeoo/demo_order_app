import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart';
import '../models/cart_model.dart';

class MustTrySection extends StatelessWidget {
  final List<ProductModel> products; // Khai báo biến nhận dữ liệu

  const MustTrySection({
    super.key,
    required this.products,
  }); // Nhận qua constructor

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildHeader("Món ngon phải thử ✨"),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildCard(context, product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, ProductModel product) {
    const Color primaryOrange = AppColors.primaryBright;
    const Color bgCard = AppColors.bgLightest;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // 1. Hình ảnh sản phẩm (Giữ nguyên)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: Image.asset(
                product.imageUrl,
                width: 130,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),

            // 2. Phần thông tin (Tên và Hàng chứa Giá + Nút)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // --- HÀNG CHỨA GIÁ TIỀN VÀ NÚT ADD ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),

                        // Nút Add
                        GestureDetector(
                          onTap: () {
                            // --- GIỮ NGUYÊN LOGIC CŨ ---
                            if (!context.read<AuthProvider>().isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                              return;
                            }

                            final defaultCartItem = CartItemModel(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              product: product,
                              quantity: 1,
                              selectedSize: 'Size S',
                              selectedIce: 'Đá vừa',
                              selectedSweetness: '70% đường',
                              selectedToppings: [],
                              itemPrice: product.price.toDouble(),
                            );
                            context.read<CartProvider>().addItem(
                              defaultCartItem,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã thêm ${product.name} vào giỏ!',
                                ),
                                backgroundColor: primaryOrange,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. SỰ KIỆN & TIN TỨC (Dạng Image Card) ---
class InfoSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;

  const InfoSection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(title, showSeeMore: true),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      items[index]['image']!,
                      width: 260,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 260,
                    child: Text(
                      items[index]['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// Helper Widget cho tiêu đề mục
Widget _buildHeader(String title, {bool showSeeMore = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
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
        // if (showSeeMore)
        //   const Row(
        //     children: [
        //       Text(
        //         "Xem thêm",
        //         style: TextStyle(color: Colors.brown, fontSize: 13),
        //       ),
        //       Icon(Icons.arrow_forward_ios, size: 12, color: Colors.brown),
        //     ],
        //   ),
      ],
    ),
  );
}
