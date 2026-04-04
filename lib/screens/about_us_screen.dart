import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Màu cam chủ đạo của App
  final Color _accentColor = AppColors.primaryBright;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("About Us", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.orangeAccent.withOpacity(0.1),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange, size: 24),
          onPressed: () => Navigator.pop(context),
        
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header với Logo/Banner
            _buildHeader(),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Phần giới thiệu
                  _buildSectionTitle("Câu chuyện của chúng tôi"),
                  const Text(
                    "Chào mừng bạn đến với ứng dụng của BrewGo. Chúng tôi bắt đầu với niềm đam mê mang lại những ly đồ uống thuần khiết từ lá trà Nhật Bản, kết hợp với phong cách phục vụ hiện đại và tiện lợi.",
                    style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 25),

                  // 3. Các giá trị cốt lõi (Dạng Grid hoặc List)
                  _buildSectionTitle("Giá trị cốt lõi"),
                  _buildValueItem(Icons.verified_user_outlined, "Chất lượng hàng đầu", "Nguyên liệu 100% tự nhiên, được tuyển chọn kỹ lưỡng."),
                  _buildValueItem(Icons.speed_outlined, "Giao hàng thần tốc", "Đảm bảo đồ uống luôn tươi ngon khi đến tay bạn."),
                  _buildValueItem(Icons.favorite_outlined, "Khách hàng là trọng tâm", "Luôn lắng nghe và cải thiện dịch vụ mỗi ngày."),
                  
                  const SizedBox(height: 25),

                  // 4. Thông tin liên hệ
                  _buildSectionTitle("Kết nối với chúng tôi"),
                  _buildContactTile(Icons.language, "Website", "www.BrewGocft.vn"),
                  _buildContactTile(Icons.phone_in_talk_outlined, "Hotline", "1900 1234"),
                  _buildContactTile(Icons.email_outlined, "Email", "support@BrewGocft.vn"),
                  
                  const SizedBox(height: 40),
                  
                  // 5. Version
                  const Center(
                    child: Text(
                      "Phiên bản 1.0.2 (2026)",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        image: const DecorationImage(
          image: AssetImage('assets/images/sukien.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomLeft,
        child: const Text(
          "BrewGo coffee & tea",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _accentColor),
      ),
    );
  }

  Widget _buildValueItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accentColor, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}