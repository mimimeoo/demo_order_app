import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

import '../models/product_model.dart';
import '../models/cart_model.dart'; 
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final CartItemModel? cartItem; // Nhận dữ liệu từ giỏ hàng nếu đang chỉnh sửa

  const ProductDetailScreen({super.key, required this.product, this.cartItem});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // === CÁC BIẾN QUẢN LÝ TRẠNG THÁI ===
  String _selectedSize = 'Size S';
  String _selectedIce = 'Đá vừa';
  String _selectedSweetness = '70% đường';

  final Map<String, double> _toppings = {
    'Trân châu trắng': 5000.0,
    'Thạch cà phê': 7000.0,
    'Kem cheese': 10000.0,
  };
  final List<String> _selectedToppings = [];

  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  final Color _primaryColor = AppColors.primaryBright; 
  final Color _bgColor = const Color(0xFFF4F4F5); // Màu nền xám nhạt (chuẩn iOS/ShopeeFood)

  @override
  void initState() {
    super.initState();
    // NẾU LÀ CHỈNH SỬA (Mở từ giỏ hàng), LẤY LẠI DỮ LIỆU CŨ ĐÃ CHỌN
    if (widget.cartItem != null) {
      _selectedSize = widget.cartItem!.selectedSize;
      _selectedIce = widget.cartItem!.selectedIce;
      _selectedSweetness = widget.cartItem!.selectedSweetness;
      _selectedToppings.addAll(widget.cartItem!.selectedToppings);
      _quantity = widget.cartItem!.quantity;
      _noteController.text = widget.cartItem!.note.isNotEmpty ? widget.cartItem!.note : '';
    }
  }

  // === LOGIC TÍNH TIỀN ===
  double get _itemPrice {
    double basePrice = widget.product.price.toDouble();

    if (_selectedSize == 'Size M') basePrice += 5000.0;
    if (_selectedSize == 'Size L') basePrice += 10000.0;

    for (String topping in _selectedToppings) {
      basePrice += _toppings[topping]!;
    }

    return basePrice;
  }

  double get _totalPrice => _itemPrice * _quantity;

  String _formatCurrency(double amount) {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(amount)}đ";
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor, 
      extendBody: true, // Cho phép body cuộn xuống dưới bottom bar trong suốt
      bottomNavigationBar: _buildBottomBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildProductInfoCard(),
                  
                  const SizedBox(height: 16),
                  _buildOptionsCard(), // Gom chung Kích cỡ, Độ ngọt, Mức đá vào 1 thẻ

                  const SizedBox(height: 16),
                  _buildToppingCard(),

                  const SizedBox(height: 16),
                  _buildNoteCard(),
                  
                  const SizedBox(height: 100), // Không gian trống cuối trang cho BottomBar lơ lửng
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // CÁC THÀNH PHẦN GIAO DIỆN (WIDGETS)
  // =======================================================

  Widget _buildSliverAppBar() {
    final isFavorite = context.watch<FavoriteProvider>().isExist(widget.product);

    return SliverAppBar(
      expandedHeight: 350, // Ảnh to, rộng rãi
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.read<FavoriteProvider>().toggleFavorite(widget.product),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.errorRed : Colors.black87,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () { /* Chức năng chia sẻ */ },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: Colors.black87, size: 22),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: widget.product.imageUrl.startsWith('http')
            ? Image.network(widget.product.imageUrl, fit: BoxFit.cover)
            : Image.asset(widget.product.imageUrl, fit: BoxFit.cover),
      ),
    );
  }

  // 1. Thẻ thông tin Header
  Widget _buildProductInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                ),
              ),
              const SizedBox(width: 12),
              
              // --- BỘ ĐẾM SỐ LƯỢNG MỚI (Nền xám nhạt bo tròn) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7), 
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQtyBtn(Icons.remove_rounded, () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }, isMinus: true),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    _buildQtyBtn(Icons.add_rounded, () {
                      setState(() => _quantity++);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              const Text("4.9/5", style: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 12),
              Text("Đã bán 2.1k+", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 13)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF2F2F7), thickness: 1),
          ),
          Text(
            widget.product.description,
            style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isMinus = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isMinus ? Colors.white : _primaryColor,
          shape: BoxShape.circle,
          border: isMinus ? Border.all(color: Colors.grey.shade300, width: 1.5) : null,
          boxShadow: isMinus ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Icon(
          icon,
          size: 18,
          color: isMinus ? Colors.black54 : Colors.white,
        ),
      ),
    );
  }

  // 2. Thẻ Tùy chọn (Gom chung Kích cỡ, Ngọt, Đá vào 1 bảng)
  Widget _buildOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSelectionRow(
            title: 'Size',
            options: ['Size S', 'Size M', 'Size L'],
            currentValue: _selectedSize,
            onSelected: (val) => setState(() => _selectedSize = val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF2F2F7), thickness: 1),
          _buildSelectionRow(
            title: 'Độ ngọt',
            options: ['50%', '70%', '100%'],
            currentValue: _selectedSweetness,
            onSelected: (val) => setState(() => _selectedSweetness = val),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF2F2F7), thickness: 1),
          _buildSelectionRow(
            title: 'Mức đá',
            options: ['Không', 'Ít', 'Nhiều'],
            currentValue: _selectedIce,
            onSelected: (val) => setState(() => _selectedIce = val),
          ),
        ],
      ),
    );
  }

  // 🔥 ĐÃ CẬP NHẬT ĐỂ HIỂN THỊ CHUNG 1 DÒNG NẰM NGANG
  Widget _buildSelectionRow({
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa chữ Size và các nút
        children: [
          SizedBox(
            width: 70, 
            child: Text(
              title,
              style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row( // Sử dụng Row và Expanded thay cho Wrap
              children: options.map((option) {
                bool isSelected = currentValue == option;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelected(option),
                    child: AnimatedContainer(
                      margin: EdgeInsets.only(right: option == options.last ? 0 : 8), // Khoảng cách giữa 3 thẻ
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10), // Giữ padding dọc, loại bỏ padding ngang tĩnh
                      alignment: Alignment.center, // Nội dung canh giữa nút
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(40), 
                        border: Border.all(
                          color: isSelected ? _primaryColor.withOpacity(0.5) : Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontFamily: 'GoogleSans',
                          color: isSelected ? _primaryColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Thẻ Topping 
  Widget _buildToppingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              "Topping",
              style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _toppings.entries.map((entry) {
                bool isSelected = _selectedToppings.contains(entry.key);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected ? _selectedToppings.remove(entry.key) : _selectedToppings.add(entry.key);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _primaryColor.withOpacity(0.5) : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontFamily: 'GoogleSans',
                            color: isSelected ? _primaryColor : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${_formatCurrency(entry.value)}',
                          style: TextStyle(
                            fontFamily: 'GoogleSans',
                            color: isSelected ? _primaryColor : Colors.black54,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Thẻ Ghi chú
  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú cho quán',
            style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Ví dụ: "Ít đá, ít ngọt", "Không lấy ống hút"...',
              hintStyle: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black38, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF4F4F5), // Nền xám nhạt
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  // === THANH BOTTOM BAR MỚI ===
  Widget _buildBottomBar() {
    bool isEditing = widget.cartItem != null;

    return Container(
      margin: EdgeInsets.only(
        left: 16, 
        right: 16, 
        bottom: MediaQuery.of(context).padding.bottom + 16
      ),
      padding: const EdgeInsets.all(6), // Padding nhỏ bao quanh nút để tạo viền trắng
      height: 68, // Cố định chiều cao
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), 
        border: Border.all(color: Colors.grey.shade200, width: 1), // 🔥 Thêm viền nhẹ để đồng bộ
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12), // 🔥 Tăng độ đậm của bóng
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hiển thị giá bên trái
          Expanded(
            flex: 4, // 🔥 Tinh chỉnh lại flex để nút có nhiều không gian hơn
            child: Padding(
              padding: const EdgeInsets.only(left: 16), 
              child: Text(
                _formatCurrency(_totalPrice),
                style: const TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
              ),
            ),
          ),
          
          // Nút bấm thêm vào giỏ bên phải
          Expanded(
            flex: 6, // 🔥 Tinh chỉnh lại flex
            child: SizedBox(
              height: double.infinity, 
              child: ElevatedButton(
                onPressed: () {
                  final cartProvider = context.read<CartProvider>();
                  
                  final cartItem = CartItemModel(
                    id: isEditing ? widget.cartItem!.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    product: widget.product,
                    quantity: _quantity,
                    selectedSize: _selectedSize,
                    selectedIce: _selectedIce,
                    selectedSweetness: _selectedSweetness,
                    selectedToppings: List.from(_selectedToppings),
                    note: _noteController.text,
                    itemPrice: _itemPrice,
                  );

                  if (isEditing) {
                    cartProvider.removeItem(widget.cartItem!.id); 
                    cartProvider.addItem(cartItem);               
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đã cập nhật giỏ hàng!', style: TextStyle(fontFamily: 'GoogleSans')),
                        backgroundColor: _primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else {
                    cartProvider.addItem(cartItem);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm ${widget.product.name} vào giỏ!', style: const TextStyle(fontFamily: 'GoogleSans')),
                        backgroundColor: _primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8), // 🔥 Giảm padding ngang
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), 
                  ),
                  elevation: 0,
                ),
                // 🔥 Sử dụng FittedBox để chữ luôn nằm gọn trên 1 dòng
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isEditing ? "Cập nhật" : "Thêm vào giỏ hàng",
                    style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}