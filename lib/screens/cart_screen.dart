import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/cart_provider.dart';
import '../models/promo_model.dart';
import 'checkout_screen.dart';
import 'my_voucher_screen.dart';
import '../models/cart_model.dart';

class CartScreen extends StatefulWidget {
  // Đã đổi tên cho đúng chuẩn camelCase
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PromoModel? selectedVoucher;

  final Color _accent = AppColors.primaryBright;
  final Color _bgLight = AppColors.bgLight;
  final Color _textGrey = AppColors.textMuted;

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} đ";
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
  // Lấy giá trị từ Firestore (0.1, 0.2, 0.5...)
  double percentage = selectedVoucher!.discountValue.toDouble(); 
  
  // Công thức: Tổng tiền hàng * 0.1
  discountAmount = subtotal * percentage;
}

// Tổng cuối cùng = (Tiền hàng + Phí ship) - Tiền giảm
double total = (subtotal + deliveryFee) - discountAmount ;
    if (total < 0) total = 0; // Đảm bảo tổng không âm

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: _buildAppBar(context, cart),
      body: items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildCartItem(items[index], cart),
                  ),
                ),
                // Truyền đầy đủ biến cần thiết vào Section này
                _buildSummarySection(
                  context,
                  subtotal,
                  deliveryFee,
                  total,
                  discountAmount,
                  items,
                ),
              ],
            ),
    );
  }

  // --- UI COMPONENTS ---

  PreferredSizeWidget _buildAppBar(BuildContext context, CartProvider cart) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Giỏ hàng",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {
            cart.clearCart();
            setState(
              () => selectedVoucher = null,
            ); // Xóa voucher khi xóa giỏ hàng
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

Widget _buildCartItem(dynamic cartItem, CartProvider cart) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24), // Bo góc sâu hơn nhìn sẽ hiện đại hơn
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Ảnh sản phẩm với Background nhẹ
        Container(
          decoration: BoxDecoration(
            color: _bgLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              cartItem.product.imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Thông tin sản phẩm
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cartItem.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Nút xóa tinh tế
                  GestureDetector(
                    onTap: () => cart.removeItem(cartItem.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Size: ${cartItem.selectedSize ?? 'M'}",
                style: TextStyle(color: _textGrey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(cartItem.itemPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: _accent,
                    ),
                  ),
                  // Bộ nút tăng giảm số lượng thiết kế lại
                  Container(
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        _qtyBtn(Icons.remove, () => cart.decreaseQuantity(cartItem.id), isMinus: true),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "${cartItem.quantity}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _qtyBtn(Icons.add, () => cart.increaseQuantity(cartItem.id)),
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
  );
}

// Cập nhật lại widget nút số lượng cho sang hơn
Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isMinus = false}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isMinus ? Colors.white : _accent,
        shape: BoxShape.circle,
        boxShadow: isMinus ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          )
        ] : null,
      ),
      child: Icon(
        icon, 
        color: isMinus ? Colors.black87 : Colors.white, 
        size: 16
      ),
    ),
  );
}
  Widget _buildSummarySection(
    BuildContext context,
    double sub,
    double delivery,
    double total,
    double discountAmount,
    List<dynamic> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phần Voucher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: _bgLight,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Mã giảm giá",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // MỞ VÍ VOUCHER
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyVoucherScreen(),
                      ),
                    );
                    if (!mounted) return;
                    if (result != null && result is PromoModel) {
                      setState(() => selectedVoucher = result);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBright,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    selectedVoucher != null ? "Đổi mã" : "Chọn",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _priceRow("Tạm tính", _formatCurrency(sub)),
          const SizedBox(height: 10),
          _priceRow("Phí giao hàng", _formatCurrency(delivery)),

          // Hiển thị dòng giảm giá nếu có chọn voucher
          if (selectedVoucher != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bọc phần Text bên trái vào Expanded
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      // Bọc tiếp Text này vào Flexible để nó tự xuống dòng nếu quá dài
                      Flexible(
                        child: Text(
                          "Giảm giá (${selectedVoucher!.title} - ${displayDiscount()})",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // (Tùy chọn) Hiện dấu ... nếu vẫn quá dài
                          maxLines: 2, // Cho phép xuống tối đa 2 dòng
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10), // Khoảng cách giữa chữ và số tiền
                Text(
                  "- ${_formatCurrency(discountAmount)}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 30, thickness: 1),
          _priceRow("TỔNG CỘNG", _formatCurrency(total), isTotal: true),
          const SizedBox(height: 20),

          // NÚT THANH TOÁN
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
            // Trong nút "Thanh toán" tại CartScreen
onPressed: () {
  final cartProvider = Provider.of<CartProvider>(context, listen: false);
  
  // Lấy danh sách values từ Map trong Provider và chuyển thành List
  List<CartItemModel> itemsForCheckout = cartProvider.items.values.toList();

  if (itemsForCheckout.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Giỏ hàng của bạn đang trống!")),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CheckoutScreen(
        cartItems: itemsForCheckout, // Truyền danh sách Model khớp 100%
        finalTotal: total,           // Giá trị total đã tính ở Cart
        discountAmount: discountAmount,
        selectedPromo: selectedVoucher,
      ),
   
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Thanh toán",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black : _textGrey,
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? _accent : Colors.black,
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Giỏ hàng của bạn đang trống"));
  }
}
