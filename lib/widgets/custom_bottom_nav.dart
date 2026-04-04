import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import provider
import '../theme/app_colors.dart';

import '../providers/favorite_provider.dart'; // Import FavoriteProvider

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Tự động đếm số lượng yêu thích
    int favoriteCount = context.watch<FavoriteProvider>().favorites.length;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(100), 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ', null),
            _buildNavItem(1, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Menu', null),
            // Trạng thái badge hiển thị tự động
            _buildNavItem(2, Icons.favorite_rounded, Icons.favorite_border_rounded, 'Yêu thích', favoriteCount > 0 ? '$favoriteCount' : null),
            _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Tài khoản', null),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, String? badge) {
    final isSelected = selectedIndex == index;

    final primaryColor = AppColors.primaryBright;
    final lightColorBg = AppColors.primaryBright.withValues(alpha: 0.05); 
    final inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic, 
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? lightColorBg : Colors.transparent, borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Icon(isSelected ? activeIcon : inactiveIcon, key: ValueKey<bool>(isSelected), color: isSelected ? primaryColor : inactiveColor, size: 26),
                ),
                
                if (badge != null)
                  Positioned(
                    top: -4, right: -6,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(badge),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(scale: value, child: child),
                      child: Container(
                        padding: const EdgeInsets.all(4.5),
                        decoration: BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle, border: Border.all(color: isSelected ? lightColorBg : Colors.white, width: 2)),
                        child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1)),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isSelected ? null : 0, 
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor), maxLines: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}