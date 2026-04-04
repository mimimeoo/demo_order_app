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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- LOGIC FORM CHỈNH SỬA ---
  String _gender = 'Chị';
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller trống, sẽ update khi mở Modal
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Hàm hiển thị Modal chỉnh sửa (Dựa trên hình ảnh bạn cung cấp)
  void _showEditProfileModal(UserModel user) {
    // Gán dữ liệu hiện tại vào các ô nhập liệu
    _nameController.text = user.displayName;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _dobController.text = user.dateOfBirth;

    // SỬA: Lấy giới tính từ database, nếu chưa có thì để 'Anh' (hoặc 'Chị')
    _gender = user.gender.isNotEmpty ? user.gender : 'Anh';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        // Dùng để update Radio trong Modal
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.bgLightest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryBright,
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.primaryBright,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Xưng hô
                const Text(
                  "Xưng hô",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Radio(
                      value: 'Anh',
                      groupValue: _gender,
                      activeColor: AppColors.primaryBright,
                      onChanged: (val) =>
                          setModalState(() => _gender = val.toString()),
                    ),
                    const Text("Anh"),
                    const SizedBox(width: 20),
                    Radio(
                      value: 'Chị',
                      groupValue: _gender,
                      activeColor: AppColors.primaryBright,
                      onChanged: (val) =>
                          setModalState(() => _gender = val.toString()),
                    ),
                    const Text("Chị"),
                  ],
                ),
                _buildModalTextField("Họ tên", _nameController),
                _buildModalTextField("Email", _emailController),
                _buildModalTextField(
                  "Số điện thoại",
                  _phoneController,
                  isReadOnly: true,
                ),
                _buildModalTextField(
                  "Ngày sinh",
                  _dobController,
                  isReadOnly: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // Trong nút ElevatedButton của Modal:
                    onPressed: () async {
                      try {
                        // Gọi hàm update với đầy đủ tham số
                        await context.read<AuthProvider>().updateProfile(
                          displayName: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          gender:
                              _gender, // Truyền biến giới tính đang chọn (Anh/Chị)
                        );

                        if (mounted) {
                          Navigator.pop(context); // Đóng Modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Cập nhật thành công!"),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  AppColors.primaryBright,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "CẬP NHẬT TÀI KHOẢN",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Xóa tài khoản",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalTextField(
    String label,
    TextEditingController controller, {
    bool isReadOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.brownText, fontSize: 13),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            readOnly: isReadOnly,
            decoration: InputDecoration(
              filled: true,
              fillColor: isReadOnly ? Colors.grey[200] : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.brown.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.brownText),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgLightest,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Tài khoản",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: auth.isLoggedIn
          ? _buildProfile(context, auth.currentUser!)
          : _buildGuest(context),
    );
  }

  Widget _buildProfile(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: Color(0xFFFFA500),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName.isEmpty
                            ? "Người dùng"
                            : user.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D26),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (user.email.isNotEmpty) ...[
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (user.phone.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgLightest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            user.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // --- NÚT EDIT ĐÃ GẮN LOGIC ---
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgLightest,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _showEditProfileModal(user),
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFFFA500),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle("Tài khoản của tôi"),
          _buildMenuGroup([
            _buildMenuTile(
              Icons.receipt_long_rounded,
              "Đơn hàng của tôi",
              () {},
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .collection('addresses')
                  .where('isDefault', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                String addressText = "Chưa thiết lập";
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  var data =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  addressText = data['label'] ?? "Đã lưu";
                }
                return _buildMenuTile(
                  Icons.location_on_outlined,
                  "Địa chỉ giao hàng",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressScreen()),
                  ),
                  trailingText: addressText,
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .collection('my_promotions')
                  .where('isUsed', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData) count = snapshot.data!.docs.length;
                return _buildMenuTile(
                  Icons.local_offer_outlined,
                  "Mã khuyến mãi",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyVoucherScreen()),
                  ),
                  trailingText: "$count mã",
                  showDivider: false,
                );
              },
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle("Hỗ trợ"),
          _buildMenuGroup([
            _buildMenuTile(Icons.info_outline_rounded, "Về chúng tôi", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              );
            }),
            _buildMenuTile(
              Icons.headset_mic_outlined,
              "Trung tâm hỗ trợ",
              () {},
            ),
            _buildMenuTile(
              Icons.article_outlined,
              "Điều khoản & Chính sách",
              () {},
              showDivider: false,
            ),
          ]),

          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFA5151),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFFA5151), width: 1.5),
                ),
              ),
              child: const Text(
                "Đăng xuất",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==========================================
  // GUEST UI (CHƯA ĐĂNG NHẬP)
  // ==========================================
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA500).withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_off_rounded,
                size: 72,
                color: Color(0xFFFFA500),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Bạn chưa đăng nhập",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D26),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Hãy đăng nhập để lưu trữ thông tin,\nquản lý đơn hàng và nhận nhiều ưu đãi!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBright,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: AppColors.primaryBright.withOpacity(0.5),
                ),
                child: const Text(
                  "ĐĂNG NHẬP / ĐĂNG KÝ",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HỖ TRỢ XÂY DỰNG UI TÀI KHOẢN
  // ==========================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? trailingText,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFFFFA500)),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1D26),
                    ),
                  ),
                ),

                if (trailingText != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA5151).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trailingText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFA5151),
                      ),
                    ),
                  ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),

          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 62, right: 16),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
              ),
            ),
        ],
      ),
    );
  }
}
