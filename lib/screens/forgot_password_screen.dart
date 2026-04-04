import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm thư viện này
import '../theme/app_colors.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final Color primaryColor = AppColors.primaryBright;
  bool _isLoading = false;

  // HÀM KIỂM TRA TÀI KHOẢN TỒN TẠI
  Future<void> _checkAccountAndSendOtp() async {
    final input = _identifierController.text.trim();

    if (input.isEmpty) {
      _showSnackBar("Vui lòng nhập Email hoặc Số điện thoại");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Kiểm tra trong Firestore xem có User nào khớp Email hoặc SĐT không
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where(input.contains('@') ? 'email' : 'phone', isEqualTo: input)
          .get();

      if (userQuery.docs.isEmpty) {
        // 2. Nếu không tìm thấy
        _showSnackBar("Không tìm thấy tài khoản này trên hệ thống!");
      } else {
        // 3. Nếu tìm thấy -> Chuyển sang trang OTP
        // Lưu ý: Ở đây bạn nên gọi hàm gửi OTP thật (như đã hướng dẫn ở phần trước)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: input)),
        );
      }
    } catch (e) {
      _showSnackBar("Đã xảy ra lỗi: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 200,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                child: const Icon(Icons.arrow_back, color: Colors.black, size: 16),
              ),
              const SizedBox(width: 8),
              const Text("Quay lại Đăng nhập", style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500))
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quên mật khẩu?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            Text(
              "Đừng lo lắng! Vui lòng nhập Email hoặc Số điện thoại đã đăng ký để nhận mã xác thực.",
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Email / Số điện thoại", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    hintText: "Nhập email hoặc số điện thoại",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkAccountAndSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Gửi mã OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}