import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _tabs = [
    "Tất cả",
    "Chờ xác nhận",
    "Đang chuẩn bị",
    "Đang giao hàng",
    "Hoàn thành",
    "Đã hủy"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(amount)}đ";
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận': return Colors.orange;
      case 'Đang chuẩn bị': return Colors.blue;
      case 'Đang giao hàng': return Colors.purple;
      case 'Hoàn thành': return Colors.green;
      case 'Đã hủy': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Đơn hàng của tôi",
          style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          // 🔥 Ép các tab căn từ lề trái, loại bỏ khoảng trống mặc định của Flutter
          tabAlignment: TabAlignment.start, 
          labelPadding: const EdgeInsets.symmetric(horizontal: 20), // Tăng khoảng cách đều giữa các Tab
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.w500, fontSize: 14),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: userId == null
          ? const Center(child: Text("Vui lòng đăng nhập để xem đơn hàng"))
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tabStatus) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('orders')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text("Đã có lỗi xảy ra"));
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

                    var orders = snapshot.data!.docs;
                    
                    // Lọc theo trạng thái của Tab
                    if (tabStatus != "Tất cả") {
                      orders = orders.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == tabStatus).toList();
                    }

                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("Chưa có đơn hàng ${tabStatus == 'Tất cả' ? 'nào' : "'$tabStatus'"} ", style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black54)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        var orderData = orders[index].data() as Map<String, dynamic>;
                        return _buildOrderCard(orderData);
                      },
                    );
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orderData) {
    List<dynamic> items = orderData['items'] ?? [];
    double totalAmount = (orderData['totalAmount'] ?? 0).toDouble();
    String status = orderData['status'] ?? 'Chờ xác nhận';
    Timestamp? createdAt = orderData['createdAt'];
    Color statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Đơn hàng #${(orderData['orderId'] ?? '').toString().length > 6 ? (orderData['orderId'] ?? '').toString().substring(0, 6).toUpperCase() : ''}",
                style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatDate(createdAt), style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 13)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF2F2F7), thickness: 1),
          ),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item['imageUrl'] != null && item['imageUrl'].toString().startsWith('http')
                        ? Image.network(item['imageUrl'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey))
                        : Image.asset(item['imageUrl'] ?? 'assets/images/default.png', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${item['quantity']}x ${item['name']}", style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.w600, fontSize: 14)),
                        if (item['size'] != null)
                          Text("${item['size']} • ${item['ice']} • ${item['sweetness']}", style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(_formatCurrency((item['price'] ?? 0).toDouble() * (item['quantity'] ?? 1).toInt()), style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            );
          }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF2F2F7), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng tiền", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontSize: 14)),
              Text(
                _formatCurrency(totalAmount),
                style: const TextStyle(fontFamily: 'GoogleSans', color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}