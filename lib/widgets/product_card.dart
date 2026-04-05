import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart'; 
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart'; 

class ProductCardVertical extends StatefulWidget {
  final ProductModel product;
  final double? width;

  const ProductCardVertical({super.key, required this.product, this.width});

  @override
  State<ProductCardVertical> createState() => _ProductCardVerticalState();
}

class _ProductCardVerticalState extends State<ProductCardVertical> with SingleTickerProviderStateMixin {
  late AnimationController _favController;

  @override
  void initState() {
    super.initState();
    _favController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _favController.value = 1.0;
  }

  @override
  void dispose() {
    _favController.dispose();
    super.dispose();
  }

  void _requireLogin() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vui lòng đăng nhập để sử dụng chức năng này!', style: TextStyle(fontFamily: 'GoogleSans')),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteProvider>();
    final isFavorite = favProvider.isExist(widget.product);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: widget.product),
          ),
        );
      },
      child: Container(
        width: widget.width,
        margin: widget.width != null 
            ? const EdgeInsets.only(right: 12, bottom: 10) 
            : const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), 
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), 
                    child: widget.product.imageUrl.startsWith('http')
                        ? Image.network(
                            widget.product.imageUrl,
                            fit: BoxFit.cover, 
                            errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                          )
                        : Image.asset(
                            widget.product.imageUrl,
                            fit: BoxFit.cover, 
                          ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque, 
                      onTap: () {
                        if (!context.read<AuthProvider>().isLoggedIn) {
                          _requireLogin();
                          return;
                        }
                        
                        _favController.reverse().then((value) => _favController.forward());
                        favProvider.toggleFavorite(widget.product);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14.0), 
                        child: ScaleTransition(
                          scale: _favController,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? AppColors.error : Colors.white,
                              size: 26,
                              shadows: const [
                                Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontFamily: 'GoogleSans',
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Colors.black87 
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.product.formattedPrice,
                        style: const TextStyle(
                          fontFamily: 'GoogleSans',
                          fontWeight: FontWeight.bold, 
                          color: Colors.black87, 
                          fontSize: 15
                        ),
                      ),
                      _buildAddButton(context),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!context.read<AuthProvider>().isLoggedIn) {
          _requireLogin();
          return;
        }
        final defaultCartItem = CartItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(), 
          product: widget.product,
          quantity: 1,
          selectedSize: 'Size S',
          selectedIce: 'Đá vừa',
          selectedSweetness: '70% đường',
          selectedToppings: [],
          itemPrice: widget.product.price.toDouble(), 
        );

        context.read<CartProvider>().addItem(defaultCartItem);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${widget.product.name} vào giỏ!', style: const TextStyle(fontFamily: 'GoogleSans')),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 700),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        width: 32, // Tăng nhẹ kích thước lên 32
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary, 
          shape: BoxShape.circle, // 🔥 ĐÃ SỬA: Biến thành hình tròn hoàn toàn
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class ProductCardHorizontal extends StatelessWidget {
  final ProductModel product;
  const ProductCardHorizontal({super.key, required this.product});

  void _requireLogin(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vui lòng đăng nhập để sử dụng chức năng này!', style: TextStyle(fontFamily: 'GoogleSans')),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), 
              blurRadius: 12, 
              offset: const Offset(0, 4)
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)), 
                child: product.imageUrl.startsWith('http')
                    ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                    : Image.asset(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name, 
                      style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.formattedPrice, 
                          style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                        ),
                        GestureDetector(
                          onTap: () {
                            if (!context.read<AuthProvider>().isLoggedIn) {
                              _requireLogin(context);
                              return;
                            }
                            
                            final defaultCartItem = CartItemModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(), 
                              product: product,
                              quantity: 1,
                              selectedSize: 'Size S',
                              selectedIce: 'Đá vừa',
                              selectedSweetness: '70% đường',
                              selectedToppings: [],
                              itemPrice: product.price.toDouble(), 
                            );

                            context.read<CartProvider>().addItem(defaultCartItem);

                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm ${product.name} vào giỏ!', style: const TextStyle(fontFamily: 'GoogleSans')),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(milliseconds: 700),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            width: 32, // Tăng nhẹ kích thước lên 32
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle, // 🔥 ĐÃ SỬA: Biến thành hình tròn hoàn toàn
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}