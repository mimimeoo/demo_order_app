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
        automaticallyImplyLeading: false,
        centerTitle: true, // Ép tiêu đề vào giữa
        leading: Center(
          // Đưa nút Back vào phần leading
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.arrow_back, color: _primaryColor, size: 20),
            ),
          ),
        ),
        title: const Text(
          "Mã ưu đãi",
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Phần bên trái (Icon/Trang trí)
              Container(
                width: 80,
                color: _primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.confirmation_number,
                  color: _primaryColor,
                  size: 30,
                ),
              ),
              // Nội dung Voucher
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.description,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "HSD: ${promo.expiryDate}",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Nút dùng ngay - UI Modern
              Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                ), // Tăng nhẹ padding cho thoáng
                child: SizedBox(
                  height: 38, // Khóa chiều cao cố định cho nút cân đối
                  width: 80, // Khóa chiều rộng để các nút đều nhau
                  child: ElevatedButton(
                    // Chuyển sang ElevatedButton để có hiệu ứng đổ bóng nhẹ (elevation)
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

                          // Kiểm tra context còn sống hay không sau khi await Firebase
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "✨ Đã thêm voucher vào ví của bạn!",
                              ),
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
                            content: Text("Vui lòng đăng nhập để sử dụng!"),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0, // Để 0 nếu bạn muốn phong cách Flat UI
                      padding: EdgeInsets
                          .zero, // Xóa padding mặc định để chữ nằm giữa
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // Bo tròn cực đại (Stadium shape)
                      ),
                    ),
                    child: const Text(
                      "Lưu",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
