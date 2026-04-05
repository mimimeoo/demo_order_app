import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../models/promo_model.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});

  final Color _primaryColor = AppColors.primaryBright;

  Future<void> saveVoucherToUser(String phoneNumber, PromoModel promo) async {
    // Đường dẫn chuẩn: users -> [SĐT] -> my_promotions -> [Mã_Voucher]
    await FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber)
        .collection(
          'my_promotions',
        ) // Tên này phải khớp 100% với MyVoucherScreen
        .doc(promo.id) // Ví dụ: 'GIAM10'
        .set({
          'title': promo.title,
          'discountValue': promo.discountValue,
          'expiryDate': promo.expiryDate,
          'isUsed':
              false, // 🔥 BẮT BUỘC: Kiểu Boolean để StreamBuilder lọc được
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<bool> checkPromoAvailability(
    String promoCode,
    String userPhoneId,
  ) async {
    final doc = await FirebaseFirestore.instance
        .collection('promotions')
        .doc(promoCode)
        .get();

    if (doc.exists) {
      List<dynamic> usedBy = doc.data()?['usedBy'] ?? [];

      // Kiểm tra trực tiếp: userPhoneId (ví dụ +84123...) có trong mảng chưa
      if (usedBy.contains(userPhoneId)) {
        return false; // Đã dùng rồi, không cho dùng nữa
      }
      return true; // Chưa dùng, hợp lệ
    }
    return false; // Mã không tồn tại
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
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
          "Mã ưu đãi",
          style: TextStyle(
            fontFamily: 'GoogleSans',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        // Lấy từ collection chung hoặc collection riêng của user tùy logic của bạn
        stream: FirebaseFirestore.instance.collection('promotions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Đã có lỗi xảy ra"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final promos = snapshot.data!.docs
              .map((doc) => PromoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              // 🔥 Lọc: Chỉ hiện mã mà user CHƯA dùng
              .where((p) => !p.isUsed )
              .toList();
          if (promos.isEmpty) {
            return const Center(child: Text("Hiện chưa có mã giảm giá nào"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            itemBuilder: (context, index) =>
                _buildPromoCard(context, promos[index]),
          );
        },
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, PromoModel promo) {
    final bgColor = const Color(0xFFFBFBFB); // Trùng màu nền Scaffold

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
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
          
          // 2. Vết cắt hình tròn và đường viền đứt nét mô phỏng xé vé (Cutout & Divider)
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
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();
                            final phoneNumber = auth.currentUser?.id;

                            if (phoneNumber != null) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(phoneNumber)
                                    .collection('my_promotions')
                                    .doc(promo.id)
                                    .set({
                                      'title': promo.title,
                                      'description': promo.description,
                                      'discountValue': promo.discountValue,
                                      'expiryDate': promo.expiryDate,
                                      'isUsed': false,
                                      'savedAt': FieldValue.serverTimestamp(),
                                    });

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✨ Đã thêm voucher vào ví của bạn!", style: TextStyle(fontFamily: 'GoogleSans')),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );

                                Navigator.pop(context);
                              } catch (e) {
                                debugPrint("Lỗi lưu voucher: $e");
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Vui lòng đăng nhập để sử dụng!", style: TextStyle(fontFamily: 'GoogleSans')),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Lưu", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 12, fontWeight: FontWeight.bold)),
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
}
