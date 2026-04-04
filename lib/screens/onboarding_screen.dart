import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart'; // 🔥 Import trang chủ của bạn
import 'package:shared_preferences/shared_preferences.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  final Color _primaryColor = AppColors.successGreen; // Màu xanh chủ đạo của app

  // Dữ liệu nội dung các trang giới thiệu
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Thưởng thức cà phê ngon",
      "description": "Khám phá hàng ngàn ly thức uống hấp dẫn được pha chế đậm đà, chuẩn vị mỗi ngày.",
      "image": "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=500" // Ảnh minh họa cà phê
    },
    {
      "title": "Giao hàng siêu tốc",
      "description": "Không cần chờ đợi lâu! Đồ uống của bạn sẽ được giao tận tay chỉ trong vòng 20 - 30 phút.",
      "image": "https://images.unsplash.com/photo-1526367790999-0150786686a2?w=500" // Ảnh minh họa giao hàng
    },
    {
      "title": "Ưu đãi ngập tràn",
      "description": "Tích điểm mỗi lần đặt hàng, nhận hàng ngàn voucher giảm giá và quà tặng hấp dẫn.",
      "image": "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=500" // Ảnh minh họa ưu đãi
    },
  ];

  // Hàm chuyển sang trang chủ
  void _goToHome() async {
    // 1. Lưu trạng thái "Đã xem Onboarding"
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    // 2. Chuyển sang HomeScreen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // NÚT BỎ QUA (SKIP)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _goToHome,
                  child: Text(
                    "Bỏ qua",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            // NỘI DUNG LƯỚT (PAGE VIEW)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hình ảnh minh họa
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            _onboardingData[index]["image"]!,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 300,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image, size: 80, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Tiêu đề
                        Text(
                          _onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 16),
                        // Mô tả
                        Text(
                          _onboardingData[index]["description"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // PHẦN ĐIỀU HƯỚNG DƯỚI ĐÁY
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dấu chấm chỉ báo trang (Dots Indicator)
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  
                  // Nút Tiếp tục / Bắt đầu
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        // Nếu đang ở trang cuối -> Vào thẳng app
                        _goToHome();
                      } else {
                        // Chuyển sang trang tiếp theo
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBright,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1 ? "Bắt đầu ngay" : "Tiếp tục",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget vẽ dấu chấm (Dot)
  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 24 : 8, // Nếu được chọn thì dãn dài ra
      decoration: BoxDecoration(
        color: isActive ? _primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}