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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
            ),
          ),
        ),
        title: const Text(
          "Ví Voucher của tôi",
          style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
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
    final bgColor = AppColors.bgLightest;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Cạnh trái (Ticket Header - Nền cam)
          Container(
            width: 100,
            height: 110,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_offer_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  promo.discountValue < 1.0 
                      ? "GIẢM ${(promo.discountValue * 100).toInt()}%" 
                      : "GIẢM ${(promo.discountValue / 1000).toInt()}K",
                  style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          
          // 2. Vết cắt hình tròn và đường viền đứt nét mô phỏng xé vé
          SizedBox(
            height: 110,
            width: 16,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(10, (_) => Container(width: 1.5, height: 4, color: Colors.grey.shade300)),
                    ),
                  ),
                ),
                Positioned(
                  top: -8, left: 0, right: 0,
                  child: Container(height: 16, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle)),
                ),
                Positioned(
                  bottom: -8, left: 0, right: 0,
                  child: Container(height: 16, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle)),
                ),
              ],
            ),
          ),
          
          // 3. Thông tin bên phải và Nút (Ticket body)
          Expanded(
            child: Container(
              height: 110,
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.description,
                        style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "HSD: ${promo.expiryDate}",
                          style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, promo);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Dùng", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 12, fontWeight: FontWeight.bold)),
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