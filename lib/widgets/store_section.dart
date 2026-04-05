import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/store_selection_screen.dart';

class NearbyStoreSection extends StatelessWidget {
  const NearbyStoreSection({super.key});

  // Dữ liệu cửa hàng được đồng bộ
  final List<Map<String, dynamic>> _stores = const [
    {
      "name": "BrewGo Quận 1",
      "address": "123 Lê Lợi, Phường Bến Thành, Quận 1, TP. HCM",
      "distance": "0.5 km",
      "isOpen": true,
      "imageUrl": "https://plus.unsplash.com/premium_photo-1664970900025-1e3099ca757a?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    },
    {
      "name": "BrewGo Thảo Điền",
      "address": "45 Xuân Thủy, Thảo Điền, Quận 2, TP. HCM",
      "distance": "3.2 km",
      "isOpen": true,
      "imageUrl": "https://images.unsplash.com/photo-1667964395069-7176f3f8a23c?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    },
    {
      "name": "BrewGo Phú Mỹ Hưng",
      "address": "SH-03 Tôn Dật Tiên, Quận 7, TP. HCM",
      "distance": "5.8 km",
      "isOpen": false,
      "imageUrl": "https://images.unsplash.com/photo-1469631423273-6995642a6a40?q=80&w=1203&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === TIÊU ĐỀ & NÚT XEM TẤT CẢ ===
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Cửa hàng gần bạn",
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StoreSelectionScreen()),
                  );
                },
                child: const Text(
                  "Xem tất cả",
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontSize: 14,
                    color: AppColors.primary, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // === DANH SÁCH CUỘN NGANG CÁC CỬA HÀNG ===
        SizedBox(
          height: 250, // 🔥 Chiều cao cố định cho list ngang để không bị cắt bóng (shadow)
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // 🔥 Cuộn ngang
            physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn mượt mà của iOS
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stores.length,
            itemBuilder: (context, index) {
              return _buildStoreCard(context, _stores[index]);
            },
          ),
        ),
      ],
    );
  }

  // === WIDGET THẺ CỬA HÀNG ===
  Widget _buildStoreCard(BuildContext context, Map<String, dynamic> store) {
    final bool isOpen = store['isOpen'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoreSelectionScreen()),
        );
      },
      child: Container(
        width: 280, // 🔥 Chiều rộng cố định cho từng thẻ khi nằm ngang
        margin: const EdgeInsets.only(right: 16, bottom: 12), // Lề phải để cách nhau 16px, lề dưới để bóng đổ (shadow) không bị cắt
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh Cover cửa hàng
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(
                    store['imageUrl'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Lớp phủ đen báo đóng cửa
                if (!isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "ĐÃ ĐÓNG CỬA",
                        style: TextStyle(
                          fontFamily: 'GoogleSans', 
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 14, 
                          letterSpacing: 1.2
                        ),
                      ),
                    ),
                  ),
                // Badge hiển thị Khoảng cách (Góc phải trên)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          store['distance'],
                          style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // 2. Thông tin Tên & Địa chỉ
            Expanded( // Dùng Expanded để căn chỉnh khoảng trống còn lại
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            store['name'],
                            style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store['address'],
                            style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 13, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Nút Chỉ đường (Nổi bật hình tròn)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_rounded, color: AppColors.primary, size: 20),
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