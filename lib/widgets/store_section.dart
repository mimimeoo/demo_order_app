import 'package:flutter/material.dart';

class NearbyStoreSection extends StatelessWidget {
  final Color kPrimaryColor = const Color(0xFF66BB6A);
  final double kHorizontalPadding = 16.0;

  const NearbyStoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu (Sau này có thể truyền từ constructor nếu lấy từ Firebase)
    final List<Map<String, dynamic>> stores = [
      {"name": "BrewGo Quận 1", "address": "123 Lê Lợi, Q.1", "distance": "0.5 km", "isOpen": true, "imageUrl": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500"},
      {"name": "BrewGo Thảo Điền", "address": "45 Xuân Thủy, Q.2", "distance": "3.2 km", "isOpen": true, "imageUrl": "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=500"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding),
          child: const Text("Cửa hàng gần bạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 245,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _buildStoreCard(stores[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    bool isOpen = store['isOpen'];
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần ảnh cửa hàng (Giữ nguyên logic Stack đã có của bạn)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(store['imageUrl'], height: 135, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isOpen ? Colors.black : Colors.grey)),
                const SizedBox(height: 4),
                Text(store['address'], style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: kPrimaryColor),
                    Text(store['distance'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(isOpen ? "Đang mở cửa" : "Đã đóng", style: TextStyle(color: isOpen ? kPrimaryColor : Colors.red, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}