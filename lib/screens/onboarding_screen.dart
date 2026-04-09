import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart'; 
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  final Color _primaryColor = AppColors.primary; // Sử dụng màu cam chủ đạo

  // Dữ liệu nội dung các trang giới thiệu
  final List<Map<String, dynamic>> _onboardingData = [
    {
      // Text đen
      "titlePart1": "Đặt đồ\nuống ",
      // Text cam
      "titlePart2": "dễ\ndàng",
      "description": "Chọn món yêu thích chỉ với vài bước đơn giản",
      "image": "https://images.unsplash.com/photo-1592858167090-2473780d894d?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8ZHJpbmtzfGVufDB8fDB8fHww" // Ảnh ly cocktail
    },
    {
      "titlePart1": "Giao hàng\nnhanh\nchóng",
      "titlePart2": "",
      "description": "Nhận đồ uống tận nơi trong thời gian ngắn",
      "image": "assets/images/ship.png" // Ảnh shipper
    },
    {
      "titlePart1": "Ưu đãi\nhấp dẫn",
      "titlePart2": "",
      "description": "Nhiều khuyến mãi dành cho bạn",
      "image": "assets/images/products/onbroading3.jpg" // Ảnh dâu tây
    },
  ];

  // Hàm chuyển sang trang chủ
  void _goToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Hàm chuyển sang trang đăng nhập
  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Nền xám cực kỳ nhẹ
      body: SafeArea(
        child: Column(
          children: [
            // --- THANH ĐIỀU HƯỚNG TRÊN CÙNG ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút Back (Chỉ hiện khi ở trang 2 và 3)
                  _currentPage > 0
                      ? GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Icon(Icons.arrow_back_rounded, color: _primaryColor, size: 24),
                        )
                      : const SizedBox(width: 24), // Giữ chỗ để nút Bỏ qua không bị lệc

                  // Nút Bỏ qua
                  GestureDetector(
                    onTap: _goToHome,
                    child: Text(
                      "Bỏ qua",
                      style: TextStyle(fontFamily: 'GoogleSans', color: _primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // --- NỘI DUNG LƯỚT (PAGE VIEW) ---
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
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Hình ảnh minh họa (Bo góc giống hình chụp)
                          Container(
                            height: MediaQuery.of(context).size.height * 0.42, // Dùng % chiều cao thay vì fix cứng để tránh overflow
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.15),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                          child: _onboardingData[index]["image"]!.startsWith('http')
                              ? Image.network(
                                  _onboardingData[index]["image"]!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                                  ),
                                )
                              : Image.asset(
                                  _onboardingData[index]["image"]!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                                  ),
                                ),
                            ),
                          ),
                          
                          const SizedBox(height: 32), // Thay Spacer() bằng SizedBox để dùng trong SingleChildScrollView

                          // Tiêu đề dạng RichText (Đen + Cam)
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2),
                              children: [
                                TextSpan(text: _onboardingData[index]["titlePart1"]),
                                TextSpan(
                                  text: _onboardingData[index]["titlePart2"],
                                  style: TextStyle(color: _primaryColor), // Đoạn chữ màu cam
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Mô tả
                          Text(
                            _onboardingData[index]["description"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 14, color: Colors.black54, height: 1.5),
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- PHẦN ĐIỀU HƯỚNG DƯỚI ĐÁY ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                children: [
                  // Dấu chấm chỉ báo trang (Dots Indicator)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Nút Tiếp theo / Bắt đầu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          _goToHome();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1 ? "Bắt đầu" : "Tiếp theo",
                        style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  // Chữ "Đăng nhập" chỉ xuất hiện ở màn hình cuối
                  AnimatedOpacity(
                    opacity: _currentPage == 2 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: GestureDetector(
                        onTap: _currentPage == 2 ? () {
                          _goToLogin(); 
                        } : null,
                        child: const Text(
                          "Đăng nhập",
                          style: TextStyle(fontFamily: 'GoogleSans', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 24 : 16, // Nếu được chọn thì dãn dài ra
      decoration: BoxDecoration(
        color: isActive ? _primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}