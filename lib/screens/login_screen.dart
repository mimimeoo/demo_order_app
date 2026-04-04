import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart';
import '../providers/auth_provider.dart' as my_auth;
import 'forgot_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../models/user_model.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false;
  final Color _primaryColor = AppColors.primary; 

  // =========================================================
  // LOGIC XỬ LÝ ĐĂNG NHẬP VÀ PHÂN LUỒNG
  // =========================================================
 // 1. Hãy đảm bảo đã import UserModel ở trên cùng
// import '../models/user_model.dart';

void _handleLogin() async {
  final phoneInput = _phoneController.text.trim();
  final pass = _passwordController.text.trim();

  if (phoneInput.isEmpty || pass.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')),
    );
    return;
  }

  // Chuẩn hóa số điện thoại
  String formattedPhone = phoneInput.startsWith('0') ? phoneInput.substring(1) : phoneInput;
  final fullPhone = "+84$formattedPhone";

  FocusScope.of(context).unfocus();

  try {
    // Lấy dữ liệu từ Firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(fullPhone).get();

    // KIỂM TRA MOUNTED SAU KHI ĐỢI FIREBASE
    if (!mounted) return;

    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tài khoản không tồn tại!')));
      return;
    }

    final userData = userDoc.data();
    if (userData?['password'] != pass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sai mật khẩu!')));
      return;
    }

    // ĐĂNG NHẬP THÀNH CÔNG -> Đưa dữ liệu vào Provider
// Trong login_screen.dart
final authProvider = context.read<my_auth.AuthProvider>();
UserModel loggedInUser = UserModel.fromSnapshot(userDoc);

// PHẢI GỌI DÒNG NÀY THÌ HEADER MỚI ĐỔI TÊN
authProvider.setCurrentUser(loggedInUser);    
   
    // Chuyển trang dựa trên Role
    String role = userData?['role'] ?? 'user';
    if (role == 'admin') {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()), (route) => false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
    }

  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
  }
}

  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái loading để vô hiệu hóa nút nếu đang xử lý
    final isLoading = context.watch<my_auth.AuthProvider>().isLoading;

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Chào mừng trở lại!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Đăng nhập để tiếp tục thưởng thức\nđồ uống yêu thích của bạn",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            _buildInputField(
              "Số điện thoại",
              "Nhập số điện thoại",
              _phoneController,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              "Mật khẩu",
              "Nhập mật khẩu",
              _passwordController,
              isPassword: true,
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                    onChanged: (v) => setState(() => _rememberMe = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Ghi nhớ đăng nhập",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: Text(
                    "Quên mật khẩu?",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Đăng Nhập",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Hoặc đăng nhập bằng",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    "Google",
                    Icons.g_mobiledata_rounded,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSocialButton(
                    "Facebook",
                    Icons.facebook_rounded,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Bạn chưa có tài khoản? ",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(
                    "Đăng Ký",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _isObscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 1.5),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String name, IconData icon, Color iconColor) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: iconColor, size: 24),
      label: Text(
        name,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
    );
  }
}
