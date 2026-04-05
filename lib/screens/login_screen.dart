import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  // --- STATE CHO VÙNG QUỐC GIA ---
  String _selectedCountryCode = '+84';
  String _selectedFlagUrl = 'https://flagcdn.com/w40/vn.png';

  final List<Map<String, String>> _countries = [
    {'name': 'Việt Nam', 'code': '+84', 'flag': 'https://flagcdn.com/w40/vn.png'},
    {'name': 'Mỹ (USA)', 'code': '+1', 'flag': 'https://flagcdn.com/w40/us.png'},
    {'name': 'Hàn Quốc', 'code': '+82', 'flag': 'https://flagcdn.com/w40/kr.png'},
    {'name': 'Nhật Bản', 'code': '+81', 'flag': 'https://flagcdn.com/w40/jp.png'},
    {'name': 'Thái Lan', 'code': '+66', 'flag': 'https://flagcdn.com/w40/th.png'},
  ];

  // Validation: Nới lỏng check length >= 8 để hỗ trợ cả số điện thoại nước ngoài
  bool get _isPhoneValid {
    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) phone = phone.substring(1);
    return phone.length >= 8; 
  }

  // --- LOGIC XỬ LÝ GỬI OTP (GỘP ĐĂNG NHẬP & ĐĂNG KÝ) ---
  Future<void> _handleNext() async {
    if (!_isPhoneValid) return;
    FocusScope.of(context).unfocus(); 

    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) phone = phone.substring(1);
    
    // Gắn mã vùng đã chọn vào số điện thoại
    final fullPhone = "$_selectedCountryCode$phone";

    final auth = context.read<AuthProvider>();
    
    // Gọi thẳng hàm gửi OTP mà không cần check Database ở bước này nữa.
    // Việc check tài khoản mới hay cũ sẽ được xử lý ngầm ở auth_provider sau khi nhập mã OTP.
    auth.verifyPhone(
      fullPhone,
      () {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: fullPhone)));
      },
      (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error, style: const TextStyle(fontFamily: 'GoogleSans')), backgroundColor: AppColors.error));
      }
    );
  }

  // --- HÀM SHOW BOTTOM SHEET CHỌN MÃ VÙNG ---
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chọn vùng / quốc gia",
                style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(country['flag']!, width: 32, height: 20, fit: BoxFit.cover),
                      ),
                      title: Text(country['name']!, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16)),
                      trailing: Text(country['code']!, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold)),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = country['code']!;
                          _selectedFlagUrl = country['flag']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Phần hình ảnh Header
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
                  right: 16,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Phần nội dung Form
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
                      "Chào mừng bạn đến với",
                      style: TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "BREWGO", 
                      style: TextStyle(
                        fontFamily: 'GoogleSans',
                        fontSize: 26, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Ô nhập số điện thoại CÓ CHỨC NĂNG ĐỔI VÙNG
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _showCountryPicker, // Gắn sự kiện mở BottomSheet
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16), 
                                    child: Image.network(_selectedFlagUrl, width: 22, height: 22, fit: BoxFit.cover)
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_selectedCountryCode, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black87)),
                                  const Icon(Icons.arrow_drop_down, color: Colors.black54, size: 20),
                                  const SizedBox(width: 4),
                                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                              onChanged: (v) => setState(() {}),
                              style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, letterSpacing: 1),
                              decoration: const InputDecoration(
                                hintText: "Nhập số điện thoại",
                                hintStyle: TextStyle(fontFamily: 'GoogleSans', color: Colors.black38, letterSpacing: 0),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row Nút Đăng nhập & FaceID
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (_isPhoneValid && !isLoading) ? _handleNext : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: Colors.grey.shade300,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      "Đăng nhập", 
                                      style: TextStyle(
                                        fontFamily: 'GoogleSans',
                                        color: _isPhoneValid ? Colors.white : Colors.white, 
                                        fontSize: 16, 
                                        fontWeight: FontWeight.w600
                                      )
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 1.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.face_retouching_natural_rounded, color: Colors.black54),
                            onPressed: () {},
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),

                    // HOẶC
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("HOẶC", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social Buttons
                    _buildWideSocialButton("Tiếp tục bằng Apple", Icons.apple, Colors.black, Colors.white),
                    _buildWideSocialButton("Tiếp tục bằng Facebook", Icons.facebook_rounded, const Color(0xFF1877F2), Colors.white),
                    _buildWideSocialButton("Tiếp tục bằng Google", Icons.g_mobiledata_rounded, Colors.white, Colors.black87, borderColor: Colors.grey.shade400),
                    
                    const SizedBox(height: 32),

                    const Text("Tiếng Việt", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontSize: 14)),
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

  Widget _buildWideSocialButton(String text, IconData icon, Color bgColor, Color textColor, {Color? borderColor}) {
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: textColor, size: 26),
        label: Text(text, style: TextStyle(fontFamily: 'GoogleSans', color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null ? BorderSide(color: borderColor, width: 1) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}