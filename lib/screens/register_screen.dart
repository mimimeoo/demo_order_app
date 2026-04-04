import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'register_otp_screen.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
Future<void> saveUserToFirestore(UserModel user) async {
  // Giả sử user.phone là "+84911222333"
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.phone) // <--- CHỈNH Ở ĐÂY: Thiết lập ID Document là Số điện thoại
      .set(user.toMap());
}
  void _handleNext() {
    String phone = _phoneController.text.trim();
    
    if (phone.startsWith('0')) {
      phone = phone.substring(1); // Bỏ số 0 ở đầu nếu có
    }
    if (phone.length >= 9) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RegisterOtpScreen(phoneNumber: "+84$phone"), // Gửi format chuẩn
        ),
      );
      
    }

    // Logic gọi API gửi mã OTP hoặc chuyển trang tiếp theo ở đây
    print("Gửi mã đến số: +84 $phone");
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
        actions: [
          // Flag chọn quốc gia (Demo như hình)
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    'https://flagcdn.com/w40/vn.png',
                    width: 32,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ],
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
                    "Nhập số điện thoại của bạn",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Chúng tôi đã gửi một mã OTP đến số điện thoại của bạn.",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 40),

                  // Ô nhập số điện thoại
                  Row(
                    children: [
                      const Text(
                        "+84 ",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                        child: VerticalDivider(
                          color: Colors.black,
                          thickness: 1,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          readOnly: true, // Không dùng bàn phím hệ thống
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 2,
                          ),
                          decoration: const InputDecoration(
                            hintText: "(000) 000-00-00",
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  // Nút Next
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBright
                        , // Màu xám nhạt như hình
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bàn phím số tùy chỉnh (Custom Numeric Keypad)
          _buildCustomKeypad(),
        ],
      ),
    );
  }

  Widget _buildCustomKeypad() {
    return Container(
      color: AppColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 1; i <= 9; i++) _buildKey(i.toString()),
          _buildKey("⌄", isIcon: true), // Nút ẩn bàn phím
          _buildKey("0"),
          _buildKey("backspace", isIcon: true), // Nút xóa
        ],
      ),
    );
  }

  Widget _buildKey(String value, {bool isIcon = false}) {
    return InkWell(
      onTap: () {
        if (value == "backspace") {
          if (_phoneController.text.isNotEmpty) {
            setState(
              () => _phoneController.text = _phoneController.text.substring(
                0,
                _phoneController.text.length - 1,
              ),
            );
          }
        } else if (value != "⌄") {
          setState(() => _phoneController.text += value);
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
