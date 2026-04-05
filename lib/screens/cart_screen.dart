import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/cart_provider.dart';
import '../models/promo_model.dart';
import 'checkout_screen.dart';
import 'my_voucher_screen.dart';
import 'product_detail_screen.dart'; 
import '../models/cart_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PromoModel? selectedVoucher;

  final Color _primaryColor = AppColors.primary; 
  final Color _bgColor = const Color(0xFFF2F2F7); // Nền xám chuẩn iOS
  final Color _textGrey = Colors.black54;

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)}đ";
  }

  String displayDiscount() {
    if (selectedVoucher == null) return "";
    double val = selectedVoucher!.discountValue;
    if (val < 1.0) {
      return "${(val * 100).toInt()}%";
    } else {
      return _formatCurrency(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();

    double subtotal = cart.totalAmount;
    double deliveryFee = items.isEmpty ? 0 : 15000;
    double discountAmount = 0;

    if (selectedVoucher != null) {
      double percentage = selectedVoucher!.discountValue.toDouble(); 
      discountAmount = subtotal * percentage;
    }

    double total = (subtotal + deliveryFee) - discountAmount;
    if (total < 0) total = 0; 

    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true, // Cho phép nội dung cuộn luồn xuống dưới Bottom Bar
      appBar: _buildAppBar(context, cart),
      bottomNavigationBar: items.isNotEmpty 
          ? _buildBottomCheckoutBar(context, total, discountAmount, items) 
          : null,
      body: items.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSectionTitle("Danh sách món"),
                        _buildCartItemsList(items, cart),
                        
                        const SizedBox(height: 24),
                        _buildSectionTitle("Khuyến mãi"),
                        _buildVoucherSection(context),

                        const SizedBox(height: 24),
                        _buildSectionTitle("Chi tiết thanh toán"),
                        _buildPriceSummary(subtotal, deliveryFee, discountAmount, total),

                        const SizedBox(height: 140), // Khoảng trống lớn để cuộn vượt qua Bottom Bar
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

  PreferredSizeWidget _buildAppBar(BuildContext context, CartProvider cart) {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      centerTitle: true,
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
      title: const Text(
        "Giỏ hàng",
        style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        if (cart.items.isNotEmpty)
          // 🔥 THAY ĐỔI: Chuyển IconButton (Thùng rác) thành TextButton (Chữ)
          TextButton(
            onPressed: () {
              cart.clearCart();
              setState(() => selectedVoucher = null); 
            },
            child: const Text(
              "Xóa tất cả", 
              style: TextStyle(
                fontFamily: 'GoogleSans', 
                color: Colors.black54, 
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // Danh sách các món trong giỏ
  Widget _buildCartItemsList(List<dynamic> items, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        padding: EdgeInsets.zero, // Bỏ padding mặc định của ListView
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF2F2F7)),
        itemBuilder: (context, index) => _buildCartItemCard(items[index], cart),
      ),
    );
  }

  // Thẻ thông tin 1 món
  Widget _buildCartItemCard(dynamic cartItem, CartProvider cart) {
    String detailsStr = [cartItem.selectedSize, cartItem.selectedIce, cartItem.selectedSweetness]
        .where((e) => e != null && e.toString().isNotEmpty).join(" • ");
    String toppingsStr = cartItem.selectedToppings.isNotEmpty ? "Topping: ${cartItem.selectedToppings.join(', ')}" : "";
    String noteStr = (cartItem.note != null && cartItem.note.isNotEmpty) ? "Ghi chú: ${cartItem.note}" : "";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: cartItem.product,
              cartItem: cartItem, 
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: cartItem.product.imageUrl.startsWith('http')
                ? Image.network(cartItem.product.imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                : Image.asset(cartItem.product.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cartItem.product.name,
                          style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => cart.removeItem(cartItem.id),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.black54, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Cấu hình món
                  Text(detailsStr, style: TextStyle(fontFamily: 'GoogleSans', color: _textGrey, fontSize: 14)),
                  if (toppingsStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(toppingsStr, style: TextStyle(fontFamily: 'GoogleSans', color: _textGrey, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  if (noteStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(noteStr, style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.orange, fontSize: 14, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),

                  const SizedBox(height: 12),
                  
                  // Giá và Nút Tăng/Giảm
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(cartItem.itemPrice),
                        style: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 17, color: _primaryColor),
                      ),
                      // Bộ đếm
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          children: [
                            _qtyBtn(Icons.remove_rounded, () => cart.decreaseQuantity(cartItem.id), isMinus: true),
                            SizedBox(
                              width: 32,
                              child: Text(
                                "${cartItem.quantity}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                            ),
                            _qtyBtn(Icons.add_rounded, () => cart.increaseQuantity(cartItem.id)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isMinus = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: isMinus ? Colors.white : _primaryColor,
          shape: BoxShape.circle,
          border: isMinus ? Border.all(color: Colors.grey.shade300) : null,
          boxShadow: isMinus ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)] : [],
        ),
        child: Icon(icon, color: isMinus ? Colors.black54 : Colors.white, size: 16),
      ),
    );
  }

  // Thẻ Khuyến mãi (Voucher)
  Widget _buildVoucherSection(BuildContext context) {
    bool hasVoucher = selectedVoucher != null;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyVoucherScreen()));
        if (!mounted) return;
        if (result != null && result is PromoModel) {
          setState(() => selectedVoucher = result);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer_rounded, color: hasVoucher ? Colors.green : Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasVoucher ? "Đã áp dụng mã" : "Thêm mã khuyến mãi",
                    style: TextStyle(fontFamily: 'GoogleSans', color: hasVoucher ? Colors.green : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (hasVoucher)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(selectedVoucher!.title, style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  // Thẻ tóm tắt Hóa đơn
  Widget _buildPriceSummary(double sub, double delivery, double discount, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _priceRow("Tạm tính", _formatCurrency(sub)),
          const SizedBox(height: 14),
          _priceRow("Phí giao hàng", _formatCurrency(delivery)),
          if (selectedVoucher != null) ...[
            const SizedBox(height: 14),
            _priceRow("Khuyến mãi", "- ${_formatCurrency(discount)}", isDiscount: true),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: 'GoogleSans', color: isDiscount ? Colors.green : _textGrey, fontSize: 15)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            color: isDiscount ? Colors.green : Colors.black87,
            fontSize: 16,
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 🔥 STICKY BOTTOM BAR BO TRÒN LƠ LỬNG
  Widget _buildBottomCheckoutBar(BuildContext context, double total, double discountAmount, List<dynamic> items) {
    return Container(
      margin: EdgeInsets.only(
        left: 16, 
        right: 16, 
        bottom: MediaQuery.of(context).padding.bottom + 16
      ),
      padding: const EdgeInsets.all(6), // Padding nhỏ bao quanh tạo không gian trắng
      height: 68, // Cố định chiều cao cân bằng với nút
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Bo tròn 100% hình viên nang
        border: Border.all(color: Colors.grey.shade200, width: 1), // 🔥 Thêm viền nhẹ để tách biệt khỏi nền trắng
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12), // 🔥 Tăng độ đậm của bóng đổ
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bên trái: Tổng tiền hiển thị rõ ràng
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tổng thanh toán", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 11, color: Colors.black54)),
                  Text(
                    _formatCurrency(total),
                    style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          
          // Bên phải: Nút bấm Thanh toán
          Expanded(
            flex: 6,
            child: SizedBox(
              height: double.infinity, // Kéo dãn chiều cao bám sát thanh Bar
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        cartItems: List<CartItemModel>.from(items), 
                        finalTotal: total,           
                        discountAmount: discountAmount,
                        selectedPromo: selectedVoucher,
                      ),
                    ),
                  ); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Nút cũng bo tròn 100%
                  elevation: 0,
                ),
                child: const Text(
                  "Thanh toán",
                  style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text("Giỏ hàng trống", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text("Cùng khám phá các món ngon nhé!", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}