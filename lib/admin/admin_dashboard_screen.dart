import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';

import '../providers/auth_provider.dart';
import 'admin_sub_screens.dart'; // Import các màn hình con
import '../screens/home_screen.dart'; // 🔥 Import HomeScreen để điều hướng về khi Đăng xuất

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color _adminColor = AppColors.adminDark;
  final Color _accentColor = AppColors.successGreen; 
  
  int _selectedIndex = 0;

  // Danh sách 8 mục menu
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_rounded, 'screen': const DashboardTab()},
    {'title': 'Products', 'icon': Icons.coffee_rounded, 'screen': const ProductsTab()},
    {'title': 'Categories', 'icon': Icons.category_rounded, 'screen': const CategoriesTab()},
    {'title': 'Orders', 'icon': Icons.receipt_long_rounded, 'screen': const OrdersTab()},
    {'title': 'Users', 'icon': Icons.people_alt_rounded, 'screen': const UsersTab()},
    {'title': 'Promotions', 'icon': Icons.local_offer_rounded, 'screen': const PromotionsTab()},
    {'title': 'Reviews', 'icon': Icons.star_rate_rounded, 'screen': const ReviewsTab()},
    {'title': 'Settings', 'icon': Icons.settings_rounded, 'screen': const SettingsTab()},
  ];

  @override
  Widget build(BuildContext context) {
    final adminName = context.watch<AuthProvider>().currentUser?.displayName ?? "Admin";
    final adminEmail = context.watch<AuthProvider>().currentUser?.email ?? "";

    return Scaffold(
      backgroundColor: AppColors.bgLighter,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Text(
          _menuItems[_selectedIndex]['title'], 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: _adminColor),
              currentAccountPicture: Container(
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _accentColor, width: 2)),
                child: Icon(Icons.shield, color: _adminColor, size: 30),
              ),
              accountName: Text(adminName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text(adminEmail),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? _accentColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: Icon(item['icon'], color: isSelected ? _accentColor : Colors.grey.shade600),
                      title: Text(
                        item['title'], 
                        style: TextStyle(color: isSelected ? _accentColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context); // Đóng menu bên trái
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            
            // =========================================================
            // NÚT ĐĂNG XUẤT CHO ADMIN (BƯỚC 3)
            // =========================================================
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                // 1. Gọi hàm đăng xuất từ AuthProvider
                await context.read<AuthProvider>().logout();
                
                // 2. Chuyển về màn hình HomeScreen (về lại chế độ khách), xóa toàn bộ lịch sử
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const HomeScreen()), 
                    (route) => false
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // Hiện nội dung tương ứng với menu được chọn
      body: _menuItems[_selectedIndex]['screen'],
    );
  }
}