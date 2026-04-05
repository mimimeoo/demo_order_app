import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedGender = 'Nam'; // Giá trị mặc định

  // === LOGIC XỬ LÝ LƯU THÔNG TIN (GIỮ NGUYÊN 100%) ===
  void _handleComplete() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập Họ và tên", style: TextStyle(fontFamily: 'GoogleSans')), 
          backgroundColor: AppColors.error
        )
      );
      return;
    }

    FocusScope.of(context).unfocus();
    
    String result = await context.read<AuthProvider>().saveNewUserInfo(
      _nameCtrl.text,
      _selectedGender,
      _emailCtrl.text,
    );

    if (result == 'success' && mounted) {
      // Lưu thành công -> Chuyển hướng vào Home
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result, style: const TextStyle(fontFamily: 'GoogleSans')), backgroundColor: AppColors.error)
        );
      }
    }
  }

  // Hàm hiển thị Form chọn Giới tính kiểu iOS BottomSheet
  void _showGenderPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text("Chọn giới tính", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                ...['Nam', 'Nữ', 'Khác'].map((gender) => ListTile(
                  title: Text(
                    gender, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontFamily: 'GoogleSans', 
                      fontSize: 18,
                      color: _selectedGender == gender ? AppColors.primary : Colors.black87,
                      fontWeight: _selectedGender == gender ? FontWeight.bold : FontWeight.normal
                    )
                  ),
                  onTap: () {
                    setState(() => _selectedGender = gender);
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

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    // Nền xám đặc trưng của iOS Settings
    const Color iosBackgroundColor = Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: iosBackgroundColor,
      appBar: AppBar(
        backgroundColor: iosBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Chặn quay lại màn OTP
        title: const Text(
          "Hồ sơ của bạn", 
          style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // === AVATAR SECTION ===
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: const BoxDecoration(
                        color: Colors.white, 
                        shape: BoxShape.circle, 
                      ),
                      child: const Icon(Icons.person_rounded, size: 50, color: Colors.black26),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary, 
                          shape: BoxShape.circle,
                          border: Border.all(color: iosBackgroundColor, width: 3)
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Thêm ảnh đại diện",
                  style: TextStyle(fontFamily: 'GoogleSans', fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 32),

              // === THÔNG TIN CÁ NHÂN ===
              _buildSectionTitle("THÔNG TIN BẮT BUỘC"),
              _buildFormGroup([
                _buildInlineTextField(
                  controller: _nameCtrl, 
                  label: "Họ và tên", 
                  hint: "Ví dụ: Nguyễn Văn A",
                ),
                _buildInlinePickerField(
                  label: "Giới tính", 
                  value: _selectedGender, 
                  onTap: _showGenderPicker,
                ),
              ]),

              const SizedBox(height: 24),

              // === THÔNG TIN LIÊN HỆ ===
              _buildSectionTitle("THÔNG TIN THÊM (TÙY CHỌN)"),
              _buildFormGroup([
                _buildInlineTextField(
                  controller: _emailCtrl, 
                  label: "Email", 
                  hint: "Nhập địa chỉ email",
                  keyboardType: TextInputType.emailAddress,
                ),
              ]),

              const SizedBox(height: 48),

              // === NÚT HOÀN TẤT ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), 
                      elevation: 0,
                    ),
                    child: isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text(
                            "HOÀN TẤT", 
                            style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Tiêu đề nhỏ phía trên các nhóm form (Giống Settings iOS)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Text(
        title, 
        style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600, letterSpacing: 0.5)
      ),
    );
  }

  // Nhóm các item lại trong một Box màu trắng bo góc có dải phân cách
  Widget _buildFormGroup(List<Widget> children) {
    List<Widget> separatedChildren = [];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) {
        // Dải phân cách mỏng, thụt lề trái 16px chuẩn iOS
        separatedChildren.add(const Divider(height: 1, indent: 16, color: Color(0xFFE5E5EA), thickness: 1));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: separatedChildren,
        ),
      ),
    );
  }

  // Item Nhập văn bản (Inline)
  Widget _buildInlineTextField({
    required TextEditingController controller, 
    required String label, 
    required String hint, 
    TextInputType keyboardType = TextInputType.text
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black87)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.right, // Căn lề phải chuẩn iOS
              style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black26, fontSize: 15, fontWeight: FontWeight.normal),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero, // Xóa khoảng trắng mặc định
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Item Chọn giá trị mở BottomSheet (Giới tính)
  Widget _buildInlinePickerField({
    required String label, 
    required String value, 
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black87)),
            ),
            Expanded(
              child: Text(
                value, 
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}