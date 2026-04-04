import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StoreSelectionScreen extends StatefulWidget {
  const StoreSelectionScreen({super.key});

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  // Màu xanh chủ đạo đồng bộ với trang chủ
  final Color _primaryColor = AppColors.successGreen;
  int _selectedStoreIndex = 0;

  // Dữ liệu mẫu danh sách cửa hàng đã bổ sung hình ảnh
  final List<Map<String, dynamic>> _stores = [
    {
      "name": "BrewGo Quận 1",
      "address": "123 Lê Lợi, Phường Bến Thành, Quận 1, TP. HCM",
      "distance": "0.5 km",
      "isOpen": true,
      "imageUrl": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500"
    },
    {
      "name": "BrewGo Thảo Điền",
      "address": "45 Xuân Thủy, Thảo Điền, Quận 2, TP. HCM",
      "distance": "3.2 km",
      "isOpen": true,
      "imageUrl": "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=500"
    },
    {
      "name": "BrewGo Phú Mỹ Hưng",
      "address": "SH-03 Tôn Dật Tiên, Quận 7, TP. HCM",
      "distance": "5.8 km",
      "isOpen": false,
      "imageUrl": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLighter,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Nút Back đồng bộ với các trang khác
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey.shade600, size: 20),
            ),
          ),
        ),
        title: const Text(
          "Chọn cửa hàng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // 1. Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm cửa hàng gần bạn...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: _primaryColor, width: 1.5),
                ),
              ),
            ),
          ),

          // 2. Danh sách cửa hàng
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stores.length,
              itemBuilder: (context, index) {
                return _buildStoreItem(index, _stores[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Thẻ hiển thị Cửa hàng
  Widget _buildStoreItem(int index, Map<String, dynamic> store) {
    bool isSelected = _selectedStoreIndex == index;
    bool isOpen = store['isOpen'];

    return GestureDetector(
      onTap: () {
        if (isOpen) {
          setState(() => _selectedStoreIndex = index);
          // Đóng trang và trả về dữ liệu cửa hàng đã chọn
          Future.delayed(const Duration(milliseconds: 300), () => Navigator.pop(context, store));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cửa hàng này hiện đang đóng cửa')));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Thêm viền xanh nếu được chọn
          border: isSelected ? Border.all(color: _primaryColor, width: 2) : Border.all(color: Colors.transparent, width: 2),
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
            // Phần Hình ảnh cửa hàng
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    store['imageUrl'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.storefront, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                // Lớp phủ xám nếu cửa hàng đóng cửa
                if (!isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "ĐÃ ĐÓNG CỬA",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                // Nổi bật dấu Tick xanh trên ảnh nếu được chọn
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle, color: _primaryColor, size: 28),
                    ),
                  ),
              ],
            ),
            // Phần Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: isOpen ? Colors.black87 : Colors.grey.shade600
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          store['address'],
                          style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: _primaryColor),
                            const SizedBox(width: 4),
                            Text(store['distance'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, size: 14, color: isOpen ? _primaryColor : Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              isOpen ? "Đang mở cửa" : "Đã đóng cửa",
                              style: TextStyle(
                                fontSize: 12,
                                color: isOpen ? _primaryColor : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nút chỉ đường
                  IconButton(
                    onPressed: () {
                      // TODO: Gọi Google Maps chỉ đường
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang mở bản đồ...')));
                    },
                    icon: Icon(Icons.directions, color: isOpen ? _primaryColor : Colors.grey, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}