import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'order_history_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  final Color _primaryColor = AppColors.successGreen;
  final Color _darkTextColor = AppColors.textDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Icon(Icons.arrow_back, color: Colors.grey.shade500, size: 20),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // ==========================================
              // 1. BIỂU TƯỢNG LY CÀ PHÊ (VẼ BẰNG FLUTTER)
              // ==========================================
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ly cà phê
                    Positioned(
                      bottom: 20,
                      child: Container(
                        width: 80,
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: _primaryColor, width: 3.5),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ),
                    // Quai ly
                    Positioned(
                      bottom: 35,
                      right: 5,
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: _primaryColor, width: 3.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // 3 Làn khói
                    Positioned(
                      top: 15,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSmokeLine(),
                          const SizedBox(width: 12),
                          _buildSmokeLine(),
                          const SizedBox(width: 12),
                          _buildSmokeLine(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // ==========================================
              // 2. TIÊU ĐỀ & MÔ TẢ
              // ==========================================
              Text(
                "Đặt hàng thành công!",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: _primaryColor
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Đơn hàng của bạn đang được chuẩn bị.\nBrewGo sẽ giao đến bạn trong khoảng 20-30 phút",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, 
                  color: _darkTextColor, 
                  height: 1.5,
                  fontWeight: FontWeight.w500
                ),
              ),
              
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
      
      // ==========================================
      // 3. HAI NÚT BẤM DƯỚI ĐÁY
      // ==========================================
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút: Theo dõi đơn hàng (Nền xanh)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBright,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Theo dõi đơn hàng",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Nút: Về trang chủ (Viền xanh)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    // Xóa hết các trang trước và về trang chủ
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  child: Text(
                    "Về trang chủ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget vẽ 1 đường khói bốc lên
  Widget _buildSmokeLine() {
    return Container(
      width: 3.5,
      height: 10,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}