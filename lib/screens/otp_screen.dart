import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'user_info_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpCtrls = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Tự động bật bàn phím ở ô đầu tiên sau khi chuyển trang
    Future.delayed(const Duration(milliseconds: 300), () => _focusNodes[0].requestFocus());
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var ctrl in _otpCtrls) { ctrl.dispose(); }
    for (var node in _focusNodes) { node.dispose(); }
    super.dispose();
  }

  // === LOGIC XÁC THỰC MÃ OTP ===
  void _handleVerify() {
    String otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) return;

    FocusScope.of(context).unfocus();
    
    context.read<AuthProvider>().verifyOTP(
      otp,
      (status) {
        if (!mounted) return;
        if (status == 'existing_user') {
          // Đã có tài khoản -> Vào thẳng Trang chủ
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
        } else {
          // Chưa có tài khoản -> Sang trang điền thông tin (Đăng ký)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserInfoScreen()));
        }
      },
      (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error, style: const TextStyle(fontFamily: 'GoogleSans')), 
          backgroundColor: AppColors.error
        ));
      }
    );
  }

  // === LOGIC GỬI LẠI MÃ ===
  void _resendOTP() {
    if (_secondsRemaining > 0) return;
    
    context.read<AuthProvider>().verifyPhone(
      widget.phoneNumber,
      () {
        if (!mounted) return;
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Đã gửi lại mã OTP", style: TextStyle(fontFamily: 'GoogleSans')), 
          backgroundColor: AppColors.success
        ));
      },
      (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error, style: const TextStyle(fontFamily: 'GoogleSans')), 
          backgroundColor: AppColors.error
        ));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    bool isComplete = _otpCtrls.every((c) => c.text.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Phần hình ảnh Header (Giống trang Đăng nhập)
            Stack(
              children: [
                Image.network(
                  'https://plus.unsplash.com/premium_photo-1706195311880-79518d91a3e3?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16, // Đổi sang trái cho nút Back
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Phần nội dung Form (Bo góc, nổi lên trên ảnh)
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    const Text(
                      "XÁC THỰC OTP", 
                      style: TextStyle(
                        fontFamily: 'GoogleSans',
                        fontSize: 26, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: "Mã OTP 6 số đã được gửi đến số\n",
                        style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black54, height: 1.5),
                        children: [
                          TextSpan(text: widget.phoneNumber, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ]
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // === 6 Ô NHẬP OTP (UI ĐỒNG BỘ LOGIN) ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 48, height: 56, // Kích thước cân đối với login inputs
                          child: TextField(
                            controller: _otpCtrls[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                            inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              filled: true, 
                              fillColor: Colors.white, 
                              contentPadding: EdgeInsets.zero, 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else {
                                  _handleVerify(); // Nhập xong ô cuối tự động verify luôn
                                }
                              } else {
                                if (index > 0) _focusNodes[index - 1].requestFocus();
                              }
                              setState(() {}); 
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),

                    // === NÚT XÁC NHẬN (UI ĐỒNG BỘ LOGIN) ===
                    SizedBox(
                      width: double.infinity, height: 52, // Đồng bộ chiều cao 52
                      child: ElevatedButton(
                        onPressed: (isComplete && !isLoading) ? _handleVerify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, 
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                          elevation: 0,
                        ),
                        child: isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Text(
                                "Xác nhận", 
                                style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // === GỬI LẠI MÃ ===
                    Center(
                      child: GestureDetector(
                        onTap: _resendOTP,
                        child: Text.rich(
                          TextSpan(
                            text: "Bạn chưa nhận được mã? ",
                            style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 14),
                            children: [
                              TextSpan(
                                text: _secondsRemaining > 0 ? "Gửi lại sau ${_secondsRemaining}s" : "Gửi lại ngay",
                                style: TextStyle(
                                  color: _secondsRemaining > 0 ? Colors.black38 : AppColors.primary, 
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ]
                          )
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}