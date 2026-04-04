import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final Color _primaryColor = AppColors.adminDark;

  @override
  void dispose() {
    for (var node in _focusNodes) { node.dispose(); }
    for (var controller in _controllers) { controller.dispose(); }
    super.dispose();
  }

  void _verifyOtp() {
    // Nối 6 số lại
    String otp = _controllers.map((c) => c.text).join();
    if(otp.length == 6) {
      // Giả lập xác thực thành công -> Chuyển sang đặt mật khẩu mới
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ 6 số OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text("Xác minh OTP", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            Text(
              "Nhập mã 6 số đã được gửi đến email/\nsố điện thoại của bạn.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Khu vực 6 ô nhập OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Container(
                  width: 48, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.bgLighter,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _focusNodes[index].hasFocus ? _primaryColor : Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(counterText: "", border: InputBorder.none),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Chưa nhận được mã? ", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const Text("Nhấn để gửi lại", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text("Gửi lại sau: 0:30", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBright, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), elevation: 0),
                child: const Text("Xác nhận", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}