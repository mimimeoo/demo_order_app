import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'setup_profile_screen.dart';

class RegisterOtpScreen extends StatefulWidget {
  final String phoneNumber;
  const RegisterOtpScreen({super.key, required this.phoneNumber});

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  // Hàm xử lý xác thực và lưu dữ liệu
 void _verifyOtp() async {
    // Chỉ xử lý khi nhập đủ 4 số và chưa đang trong quá trình verify
    if (_otpController.text.length == 4) {
      try {
        // 1. Lưu tài khoản TẠM THỜI lên Firestore
        // Quan trọng: Phải dùng set với merge: true để khởi tạo document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.phoneNumber) // widget.phoneNumber phải là "+84xxx" (không dấu cách)
            .set({
              'phoneNumber': widget.phoneNumber,
              'createdAt': DateTime.now(),
              'role': 'user',
              'isProfileComplete': false, // Đánh dấu là chưa xong profile
            }, SetOptions(merge: true));

        if (!mounted) return;

        // 2. Thông báo thành công (Tùy chọn)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác thực OTP thành công!'), backgroundColor: Colors.green),
        );

        // 3. ĐIỀU HƯỚNG SANG SETUP PROFILE (Dùng pushReplacement)
        // Lệnh này sẽ thay thế màn hình OTP bằng màn hình Setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SetupProfileScreen(phoneNumber: widget.phoneNumber),
          ),
        );
      } catch (e) {
        debugPrint("Lỗi lưu database: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "Nhập OTP",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: "Chúng tôi đã gửi một mã đến "),
                        TextSpan(
                          text: widget.phoneNumber,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Khu vực hiển thị mã OTP (Dùng Row để tạo khoảng cách gạch chân)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (index) => _buildOTPDisplayBox(index),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "Gửi lại mã trong 00:30",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 40),
                  // Nút Verify đồng bộ style xám nhạt
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBright,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Xác nhận",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bàn phím tùy chỉnh (Keypad) đồng bộ hoàn toàn với RegisterScreen
          _buildCustomKeypad(),
        ],
      ),
    );
  }

  // Widget hiển thị từng ký tự OTP đã nhập
  Widget _buildOTPDisplayBox(int index) {
    String char = "";
    if (_otpController.text.length > index) {
      char = _otpController.text[index];
    }

    return Container(
      width: 60,
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: char.isNotEmpty ? Colors.black : Colors.grey.shade300,
            width: 2,
          ),
        ),
      ),
      child: Text(
        char,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Bàn phím Custom Keypad - Giữ nguyên logic từ RegisterScreen để đồng bộ
  Widget _buildCustomKeypad() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 1; i <= 9; i++) _buildKey(i.toString()),
          _buildKey("⌄", isIcon: true),
          _buildKey("0"),
          _buildKey("backspace", isIcon: true),
        ],
      ),
    );
  }

  Widget _buildKey(String value, {bool isIcon = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          if (value == "backspace") {
            if (_otpController.text.isNotEmpty) {
              _otpController.text = _otpController.text.substring(
                0,
                _otpController.text.length - 1,
              );
            }
          } else if (value != "⌄") {
            if (_otpController.text.length < 4) {
              _otpController.text += value;
            }
          }
        });

        // Tự động verify khi đủ 4 số
        if (_otpController.text.length == 4) {
          _verifyOtp();
        }
      },
      child: Center(
        child: isIcon
            ? Icon(
                value == "backspace"
                    ? Icons.backspace_outlined
                    : Icons.keyboard_arrow_down,
                color: Colors.black,
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
