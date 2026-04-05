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
      backgroundColor: Colors.white, // Nền trắng chuẩn Clean UI
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87), 
          onPressed: () => Navigator.pop(context)
        )
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Message (Tạo điểm nhấn thị giác)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_rounded, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 24),

              const Text("Nhập mã xác nhận", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  text: "Mã OTP 6 số đã được gửi đến số điện thoại\n",
                  style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black54, height: 1.5),
                  children: [
                    TextSpan(text: widget.phoneNumber, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ]
                )
              ),
              const SizedBox(height: 40),

              // === 6 Ô NHẬP OTP (UI HIỆN ĐẠI) ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48, height: 60,
                    child: TextField(
                      controller: _otpCtrls[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        filled: true, 
                        fillColor: AppColors.background, // Hoặc Colors.grey.shade100
                        contentPadding: EdgeInsets.zero, // Căn giữa Text hoàn hảo
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
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
              const SizedBox(height: 48),

              // === NÚT XÁC NHẬN ===
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: (isComplete && !isLoading) ? _handleVerify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                    elevation: 0,
                  ),
                  child: isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text(
                          "XÁC NHẬN", 
                          style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
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
              )
            ],
          ),
        ),
      ),
    );
  }
}