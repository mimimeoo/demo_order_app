import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/product_card.dart';
import '../providers/favorite_provider.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Gọi danh sách yêu thích
    final favorites = context.watch<FavoriteProvider>().favorites;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Món yêu thích", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite, color: AppColors.errorRed, size: 20),
                )
              ],
            ),
          ),

          Expanded(
            child: favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Bạn chưa thích món nào", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text("Hãy thả tim những món bạn muốn thử nhé!", style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120), 
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final p = favorites[index];
                      return ProductCardHorizontal(product: p);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}