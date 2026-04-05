import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import '../screens/my_voucher_screen.dart';
import '../screens/address_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/order_history_screen.dart';

// =======================================================
// 1. MÀN HÌNH TÀI KHOẢN CHÍNH (PROFILE SCREEN)
// =======================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color iosBackgroundColor = const Color(0xFFF2F2F7);
  final Color iosDividerColor = const Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: iosBackgroundColor, 
      appBar: AppBar(
        backgroundColor: iosBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text("Tài khoản", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: auth.isLoggedIn ? _buildProfile(context, auth.currentUser!) : _buildGuest(context),
    );
  }

  // === GIAO DIỆN KHI ĐÃ ĐĂNG NHẬP ===
  Widget _buildProfile(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // --- HEADER THÔNG TIN CHUNG ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName.isEmpty ? "Người dùng" : user.displayName,
                          style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (user.phone.isNotEmpty)
                          Text(user.phone, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 14, color: Colors.black54)),
                        if (user.email.isNotEmpty)
                          Text(user.email, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 14, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- HOẠT ĐỘNG MUA SẮM ---
          _buildSectionTitle("HOẠT ĐỘNG MUA SẮM"),
          _buildFormGroup([
            _buildMenuTile(Icons.receipt_long_rounded, Colors.blue, "Đơn hàng của tôi", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
            }),
            _buildMenuTile(Icons.favorite_rounded, Colors.red, "Sản phẩm yêu thích", () {}),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.id).collection('my_promotions').where('isUsed', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData) count = snapshot.data!.docs.length;
                return _buildMenuTile(
                  Icons.local_offer_rounded, Colors.orange, "Mã khuyến mãi", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVoucherScreen())), 
                  trailingText: count > 0 ? "$count mã" : null, 
                  showDivider: false
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // --- CÀI ĐẶT TÀI KHOẢN ---
          _buildSectionTitle("CÀI ĐẶT TÀI KHOẢN"),
          _buildFormGroup([
            _buildMenuTile(Icons.person_rounded, Colors.purple, "Sửa thông tin cá nhân", () {
              // 🚀 CHUYỂN SANG MÀN HÌNH SỬA THÔNG TIN ĐỘC LẬP
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)));
            }),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.id).collection('addresses').where('isDefault', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                String addressText = "Chưa thiết lập";
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  addressText = data['label'] ?? "Đã lưu";
                }
                return _buildMenuTile(
                  Icons.location_on_rounded, Colors.green, "Địa chỉ giao hàng", 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())), 
                  trailingText: addressText
                );
              },
            ),
            _buildMenuTile(Icons.settings_rounded, Colors.grey.shade600, "Cài đặt chung", () {}, showDivider: false),
          ]),

          const SizedBox(height: 24),

          // --- HỖ TRỢ ---
          _buildSectionTitle("HỖ TRỢ"),
          _buildFormGroup([
            _buildMenuTile(Icons.info_rounded, Colors.lightBlue, "Về chúng tôi", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen()))),
            _buildMenuTile(Icons.headset_mic_rounded, Colors.teal, "Trung tâm hỗ trợ", () {}),
            _buildMenuTile(Icons.article_rounded, Colors.brown, "Điều khoản & Chính sách", () {}, showDivider: false),
          ]),

          const SizedBox(height: 32),

          // --- ĐĂNG XUẤT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () => context.read<AuthProvider>().logout(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text("Đăng xuất", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === GIAO DIỆN KHÁCH (CHƯA ĐĂNG NHẬP) ===
  Widget _buildGuest(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.person_off_rounded, size: 72, color: AppColors.primary), 
            ),
            const SizedBox(height: 32),
            const Text("Bạn chưa đăng nhập", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text("Hãy đăng nhập để lưu trữ thông tin,\nquản lý đơn hàng và nhận nhiều ưu đãi!", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black54, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("ĐĂNG NHẬP / ĐĂNG KÝ", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Text(title, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildFormGroup(List<Widget> children) {
    List<Widget> separatedChildren = [];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) separatedChildren.add(Divider(height: 1, indent: 56, color: iosDividerColor, thickness: 1));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(children: separatedChildren),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, Color iconBgColor, String title, VoidCallback onTap, {String? trailingText, bool showDivider = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))),
            if (trailingText != null)
              Text(trailingText, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 14, color: Colors.black45)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// 2. MÀN HÌNH CHỈNH SỬA THÔNG TIN ĐỘC LẬP
// =======================================================
class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color iosBackgroundColor = const Color(0xFFF2F2F7);
  final Color iosDividerColor = const Color(0xFFE5E5EA);

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  String _gender = 'Anh';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _dobController = TextEditingController(text: widget.user.dateOfBirth);
    _gender = widget.user.gender.isNotEmpty ? widget.user.gender : 'Anh';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Cập nhật thông tin
  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender, 
      );
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!", style: TextStyle(fontFamily: 'GoogleSans'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e", style: const TextStyle(fontFamily: 'GoogleSans'))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hiện Modal chọn Giới tính
  void _showGenderPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text("Chọn xưng hô", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                ...['Anh', 'Chị', 'Khác'].map((g) => ListTile(
                  title: Text(g, textAlign: TextAlign.center, style: TextStyle(
                    fontFamily: 'GoogleSans', fontSize: 18,
                    color: _gender == g ? AppColors.primary : Colors.black87,
                    fontWeight: _gender == g ? FontWeight.bold : FontWeight.normal
                  )),
                  onTap: () {
                    setState(() => _gender = g);
                    Navigator.pop(context);
                  },
                )).toList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }
    );
  }

  // Hiện DatePicker chọn Ngày sinh
  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), 
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: Colors.black87),
          ),
          child: child!,
        );
      }
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iosBackgroundColor,
      appBar: AppBar(
        backgroundColor: iosBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          // ĐÃ ĐỔI THÀNH NÚT BACK DẠNG MŨI TÊN CHỈ TRÁI
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87), 
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text("Sửa hồ sơ", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          _isLoading 
            ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : TextButton(
                onPressed: _handleSave, 
                child: const Text("Lưu", style: TextStyle(fontFamily: 'GoogleSans', color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
              )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      widget.user.displayName.isNotEmpty ? widget.user.displayName[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: iosBackgroundColor, width: 3)),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle("THÔNG TIN CÁ NHÂN"),
            _buildFormGroup([
              _buildInlineTextField("Họ và tên", _nameController),
              _buildInlinePickerField("Xưng hô", _gender, _showGenderPicker),
              _buildInlinePickerField("Ngày sinh", _dobController.text.isEmpty ? "Chọn ngày" : _dobController.text, _selectDate),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle("THÔNG TIN LIÊN HỆ"),
            _buildFormGroup([
              _buildInlineTextField("Số điện thoại", _phoneController, isReadOnly: true),
              _buildInlineTextField("Email", _emailController, keyboardType: TextInputType.emailAddress),
            ]),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers cho Form Sửa ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Text(title, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildFormGroup(List<Widget> children) {
    List<Widget> separatedChildren = [];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) separatedChildren.add(Divider(height: 1, indent: 16, color: iosDividerColor, thickness: 1));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(children: separatedChildren),
      ),
    );
  }

  Widget _buildInlineTextField(String label, TextEditingController controller, {bool isReadOnly = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black87))),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: isReadOnly ? Colors.black45 : Colors.black87, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlinePickerField(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black87))),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500))),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}