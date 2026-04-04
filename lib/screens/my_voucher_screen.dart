import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../models/promo_model.dart'; // Đảm bảo bạn đã import model này

class MyVoucherScreen extends StatelessWidget {
  const MyVoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.bgLightest,
      appBar: AppBar(
        title: const Text(
          "Ví Voucher của tôi",
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userId == null
          ? const Center(child: Text("Vui lòng đăng nhập để xem voucher"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('my_promotions')
                  .where('isUsed', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Đã có lỗi xảy ra"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final myVouchers = snapshot.data!.docs;
                if (myVouchers.isEmpty) return _buildEmptyState();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: myVouchers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var doc = myVouchers[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    // Chuyển Map thành PromoModel để gửi về giỏ hàng
                    // Dùng doc.id làm ID của PromoModel
                    PromoModel promo = PromoModel.fromMap(data, doc.id);

                    return _buildVoucherCard(context, promo);
                  },
                );
              },
            ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, PromoModel promo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 10, color: AppColors.primaryBright), // Màu cam theo style Cart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              promo.description,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "HSD: ${promo.expiryDate}",
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      // NÚT DÙNG - Gửi dữ liệu về Cart_Screen
                      ElevatedButton(
                        onPressed: () {
                          // LỆNH QUAN TRỌNG: Trả đối tượng promo về màn hình trước
                          Navigator.pop(context, promo);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBright,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Dùng", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_num_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Bạn chưa có mã giảm giá nào", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }
}