import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

import '../models/product_model.dart';
import '../models/cart_model.dart'; // 🔥 Import model giỏ hàng mới
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

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

  final Color _primaryColor = AppColors.primaryBright; // Màu cam chủ đạo cho các phần được chọn và nút bấm

  // === LOGIC TÍNH TIỀN ===
  // Tính giá của 1 ly (Gốc + Size + Topping)
  double get _itemPrice {
    double basePrice = widget.product.price.toDouble();

    if (_selectedSize == 'Size M') basePrice += 5000.0;
    if (_selectedSize == 'Size L') basePrice += 10000.0;

    for (String topping in _selectedToppings) {
      basePrice += _toppings[topping]!;
    }

    return basePrice;
  }

  // Tính tổng tiền = Giá 1 ly * Số lượng
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
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(),
                _buildDivider(),

                // Dòng chọn Size
                _buildSelectionRow(
                  title: 'Size',
                  options: ['Size S', 'Size M', 'Size L'],
                  currentValue: _selectedSize,
                  onSelected: (val) => setState(() => _selectedSize = val),
                ),
                _buildDivider(),

                // Dòng chọn Độ ngọt
                _buildSelectionRow(
                  title: 'Độ ngọt',
                  options: ['50%', '70%', '100%'],
                  currentValue: _selectedSweetness,
                  onSelected: (val) => setState(() => _selectedSweetness = val),
                ),
                _buildDivider(),

                // Dòng chọn Đá
                _buildSelectionRow(
                  title: 'Mức đá',
                  options: ['Không', 'Ít', 'Nhiều'],
                  currentValue: _selectedIce,
                  onSelected: (val) => setState(() => _selectedIce = val),
                ),
                _buildDivider(),

                _buildToppingSection(),
                _buildDivider(),

                _buildNoteSection(),
                const SizedBox(height: 24),
              ],
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
    final isFavorite = context.watch<FavoriteProvider>().isExist(
      widget.product,
    );

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () =>
              context.read<FavoriteProvider>().toggleFavorite(widget.product),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.errorRed : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            /* Chức năng chia sẻ */
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined, color: Colors.black),
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

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng chứa Tên sản phẩm và Bộ đếm số lượng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // --- BỘ ĐẾM SỐ LƯỢNG (Layout theo hình mẫu) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100, // Màu nền nhạt cho capsule
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildQtyBtn(Icons.remove, () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildQtyBtn(Icons.add, () {
                      setState(() => _quantity++);
                    }, isAdd: true),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 20),
              SizedBox(width: 4),
              Text("4.9/5", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Hàm phụ để build nút nhỏ trong bộ đếm cho gọn code
  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          // Nút cộng có màu cam nổi bật theo mẫu, nút trừ màu trắng
          color: isAdd ? Colors.orangeAccent : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: isAdd ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }

  // --- CẬP NHẬT SECTION CHỌN SIZE ---
  Widget _buildSelectionRow({
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Căn lề trên cho đẹp khi Wrap xuống dòng
        children: [
          // Tiêu đề mục (Size, Đá, Đường...)
          SizedBox(
            width: 80, // Độ rộng cố định để các hàng thẳng cột với nhau
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ), // Căn giữa nhẹ với hàng nút
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D26),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Danh sách các nút lựa chọn
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((option) {
                bool isSelected = currentValue == option;
                return GestureDetector(
                  onTap: () => onSelected(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.orange : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
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

  Widget _buildToppingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Topping'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _toppings.entries.map((entry) {
              bool isSelected = _selectedToppings.contains(entry.key);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected
                        ? _selectedToppings.remove(entry.key)
                        : _selectedToppings.add(entry.key);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _primaryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: isSelected ? _primaryColor : Colors.black,
                          fontWeight:  isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '+${_formatCurrency(entry.value)}',
                        style: TextStyle(
                          color: isSelected ? _primaryColor : Colors.black,
                          fontWeight:  isSelected ? FontWeight.bold : FontWeight.normal,
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
    );
  }

  Widget _buildNoteSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú cho quán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1D26),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ví dụ: "Ít đá, ít ngọt", "Không lấy ống hút"...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Hiển thị giá bên trái
            Expanded(
              child: Center(
                child: Text(
                  _formatCurrency(_totalPrice),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Nút bấm bên phải
            ElevatedButton(
              onPressed: () {
                final cartItem = CartItemModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),

                  product: widget.product,

                  quantity: _quantity,

                  selectedSize: _selectedSize,

                  selectedIce: _selectedIce,

                  selectedSweetness: _selectedSweetness,

                  selectedToppings: List.from(_selectedToppings),

                  note: _noteController.text,

                  itemPrice: _itemPrice,
                );

                context.read<CartProvider>().addItem(cartItem);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thêm ${widget.product.name} vào giỏ!'),
                    backgroundColor: _primaryColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Add to Cart",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1D26),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 6, color: AppColors.bgLighter);
  }
}
