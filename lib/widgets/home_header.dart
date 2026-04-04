import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/promo_screen.dart';

class HomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final String userName; // 1. THÊM DÒNG NÀY
  const HomeHeader({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    required this.userName, // 2. THÊM DÒNG NÀY});
  });
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final userName = auth.currentUser?.displayName ?? "Khách";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoggedIn)
                      Text.rich(
                        TextSpan(
                          text: "Xin chào,\n",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(
                              text: "$userName!",
                              style: const TextStyle(color: AppColors.primaryBright)),
                          ],
                        ),
                      )
                    else
                      const Text(
                        "Xin chào!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                    const SizedBox(height: 6),
                    const Text(
                      "Bạn muốn uống gì hôm nay?",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryBright,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (isLoggedIn)
                Row(
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('promotions')
                          .snapshots(),
                      builder: (context, snapshot) {
                        // Mặc định là 0 nếu đang tải hoặc lỗi
                        int count = 0;
                        if (snapshot.hasData) {
                          count = snapshot.data!.docs.length;
                        }
                        return _buildTopIcon(
                          Icons.local_offer_outlined,
                          size: const Size(28, 28),
                          color: Colors.black, // Đổi màu tại đây
                          badgeCount: count, // Số lượng thực tế từ Firebase
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PromoScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildTopIcon(
                          size: const Size(28, 28),
                          Icons.notifications_none_rounded,
                          color: Colors.black,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Trang thông báo')),
                            );
                          },
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBright,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    "Đăng Nhập",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // THANH TÌM KIẾM CÓ CHỨC NĂNG
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
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
                    controller: searchController,
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm đồ uống...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      // Hiện nút X nếu đã có chữ
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: onClear,
                            )
                          : null,
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                IconButton(
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primaryBright,
                    size: 22,
                  ),
                  onPressed: () {},
                  splashRadius: 20,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon(
    IconData icon, {
    required VoidCallback onTap,
    int badgeCount = 0,
    Color color = Colors.white,
    Size? size,
  }) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color, size: 28), // Sử dụng biến color ở đây
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.errorRed, // Màu đỏ của badge
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
