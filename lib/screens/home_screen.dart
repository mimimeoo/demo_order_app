import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../widgets/carousel_slider.dart';
import '../widgets/category_list.dart';
import '../widgets/home_header.dart';
import '../widgets/home_section.dart';
import '../widgets/product_section.dart'; 
import '../widgets/store_section.dart';
import '../widgets/custom_bottom_nav.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'favorite_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'address_screen.dart';
import 'store_selection_screen.dart';

String removeVietnameseTones(String str) {
  str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');
  str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
  str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
  str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
  str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
  str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
  str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
  str = str.replaceAll(RegExp(r'[Đ]'), 'D');
  return str.toLowerCase();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CategoryModel? selectedCategory;
  late Future<Map<String, dynamic>> _appDataFuture;

  final Color kPrimaryColor = AppColors.primary;
  final double kHorizontalPadding = 16.0; // Margin mặc định toàn trang

  @override
  void initState() {
    super.initState();
    _appDataFuture = loadAppData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> loadAppData() async {
    try {
      final db = FirebaseFirestore.instance;
      final categorySnapshot = await db.collection('categories').get();
      final categories = categorySnapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
      final productSnapshot = await db.collection('products').get();
      final products = productSnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
      categories.sort((a, b) => a.id.compareTo(b.id));
      return {'categories': categories, 'products': products};
    } catch (e) {
      throw Exception("Lỗi kết nối Firebase");
    }
  }

  final List<Map<String, String>> sampleEvents = [
    {"title": "BrewGo xin chào Đồng Chill Vincom Times City", "image": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500"},
    {"title": "BrewGo xin chào Đồng Chill Vincom Times City", "image": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500"},
  ];

  final List<Map<String, String>> sampleNews = [
    {"title": "PHAN XI PĂNG LONG NHÃN - Vị trà núi rừng", "image": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500"},
    {"title": "PHAN XI PĂNG LONG NHÃN - Vị trà núi rừng", "image": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500"},
  ];

  @override
  Widget build(BuildContext context) {
    int cartItemCount = context.watch<CartProvider>().itemCount;
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    Widget currentScreen;
    
    switch (_selectedIndex) {
      case 0:
        currentScreen = _buildHomeContent(currentUser);
        break;
      case 1:
        currentScreen = const MenuScreen();
        break;
      case 2:
        currentScreen = const FavoriteScreen();
        break;
      case 3:
        currentScreen = const ProfileScreen();
        break;
      default:
        currentScreen = _buildHomeContent(currentUser);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, 
      extendBody: true,
      floatingActionButton: cartItemCount > 0 ? _buildFloatingCart(cartItemCount) : null,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: currentScreen),
    );
  }

  Widget _buildHomeContent(UserModel? user) {
    return FutureBuilder<Map<String, dynamic>>(
      key: const ValueKey('HomeTab'),
      future: _appDataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Đang bảo trì..."));
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: kPrimaryColor));

        final categories = snapshot.data!['categories'] as List<CategoryModel>;
        final allProducts = snapshot.data!['products'] as List<ProductModel>;

        bool isSearching = _searchQuery.isNotEmpty;
        List<ProductModel> searchResults = isSearching
            ? allProducts.where((p) => removeVietnameseTones(p.name).contains(removeVietnameseTones(_searchQuery))).toList()
            : [];

        List<ProductModel> filteredProducts = selectedCategory == null
            ? allProducts
            : allProducts.where((p) => p.categoryId == selectedCategory!.id).toList();

        final homeProducts = filteredProducts.where((p) => p.showOnHome).toList();
        final bestSellers = homeProducts.where((p) => p.isPopular).toList();
        final recommended = homeProducts.where((p) => !p.isPopular).toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 252, 248, 245),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      HomeHeader(
                        userName: context.watch<AuthProvider>().currentUser?.displayName ?? "Khách", 
                        searchController: _searchController,
                        onSearch: (value) => setState(() => _searchQuery = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      if (!isSearching) ...[
                        CustomCarouselSlider(),
                        const SizedBox(height: 16),
                        _buildDeliveryInfo(context),
                        const SizedBox(height: 16), // Sửa thành 16
                      ],
                    ],
                  ),
                ),
              ),

              if (isSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ProductSection(title: "Kết quả tìm kiếm", products: searchResults),
                )
              else ...[
                const SizedBox(height: 16), // Sửa thành 16
                CategoryList(categories: categories, onCategorySelected: (category) => setState(() => selectedCategory = category)),
                const SizedBox(height: 16), // Sửa thành 16
                ProductSection(title: "Bán chạy nhất", products: bestSellers, isHorizontal: true),
                const SizedBox(height: 16), // Sửa thành 16
                MustTrySection(products: bestSellers),
                const SizedBox(height: 16), // Sửa thành 16
                ProductSection(title: "Gợi ý cho bạn", products: recommended),
                const SizedBox(height: 16), // Sửa thành 16
                InfoSection(title: "Sự kiện", items: sampleEvents),
                const SizedBox(height: 16), 
                InfoSection(title: "Tin tức", items: sampleNews),
                const SizedBox(height: 16), // Sửa thành 16
                const NearbyStoreSection(),
              ],
              const SizedBox(height: 100), 
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCart(int cartItemCount) {
    return FloatingActionButton(
      backgroundColor: AppColors.primary,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 26, color: Colors.white),
          Positioned(
            right: -4,
            top: -6,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(cartItemCount),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor, width: 2),
                ),
                child: Text(
                  '$cartItemCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kHorizontalPadding),
      child: InkWell(
        onTap: () {
          final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
          isLoggedIn
              ? _showDeliveryBottomSheet(context)
              : Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color.fromARGB(255, 250, 243, 236), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.delivery_dining, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Giao hàng tận nơi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text("Sản phẩm giao đến địa chỉ của bạn", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text("Phương thức nhận hàng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildMethodOption(
              title: "Giao hàng tận nơi",
              subtitle: "Chúng tôi sẽ giao đến địa chỉ của bạn",
              icon: Icons.delivery_dining_outlined,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen()));
              },
            ),
            const SizedBox(height: 16),
            _buildMethodOption(
              title: "Đến lấy trực tiếp",
              subtitle: "Tự lấy hàng tại chi nhánh gần nhất",
              icon: Icons.storefront_outlined,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreSelectionScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}