import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Đảm bảo các đường dẫn này chính xác với project của bạn
import '../providers/auth_provider.dart';
import '../models/promo_model.dart';
import '../models/cart_model.dart';
import '../providers/cart_provider.dart';
import 'address_screen.dart';
import 'store_selection_screen.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.discountAmount,
    this.selectedPromo,
    required this.finalTotal,
    required this.cartItems,
  });

  final double discountAmount;
  final PromoModel? selectedPromo;
  final double finalTotal;
  final List<CartItemModel> cartItems;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // --- Cấu hình màu sắc & Trạng thái ---
  final Color _primaryColor = AppColors.primary; 
  final Color _bgColor = const Color(0xFFF2F2F7);

  bool _isDelivery = true;
  bool _isSuccessPageVisible = false; 
  
  int _selectedPaymentIndex = 0; 

  String _pickupPerson = "Vui lòng nhập tên của bạn";
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedStore;

  String _formatCurrency(double amount) {
    final format = NumberFormat("#,##0", "vi_VN");
    return format.format(amount);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> completePayment(String promoId, String phoneNumber) async {
    final batch = FirebaseFirestore.instance.batch();

    DocumentReference promoRef = FirebaseFirestore.instance
        .collection('promotions')
        .doc(promoId);
    DocumentReference userPromoRef = FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber)
        .collection('my_promotions')
        .doc(promoId);

    batch.update(promoRef, {
      'usedBy': FieldValue.arrayUnion([phoneNumber]),
    });

    batch.update(userPromoRef, {'isUsed': true});

    await batch.commit().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception("Kết nối mạng quá chậm, vui lòng thử lại!");
      },
    );
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressScreen()),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  Future<void> _pickStore() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoreSelectionScreen()),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedStore = result;
      });
    }
  }

  void _showEditPickupPerson() {
    TextEditingController controller = TextEditingController(
      text: _pickupPerson,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text(
              "Người nhận hàng",
              style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16),
              decoration: InputDecoration(
                hintText: "Nhập tên người nhận...",
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() => _pickupPerson = controller.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Xác nhận",
                style: TextStyle(fontFamily: 'GoogleSans', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = widget.cartItems.fold(0.0, (sum, item) => sum + (item.itemPrice * item.quantity));
    double deliveryFee = _isDelivery ? 15000.0 : 0.0;
    double total = subtotal + deliveryFee - widget.discountAmount;
    if (total < 0) total = 0;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _bgColor,
          extendBody: true, // 🔥 Cho phép nội dung cuộn luồn xuống dưới Bottom Bar
          appBar: _buildAppBar(context),
          bottomNavigationBar: _buildBottomButton(total),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildDeliveryTabs(),
                const SizedBox(height: 24),
                _buildProductListPreview(),
                const SizedBox(height: 24),
                _isDelivery ? _buildDeliveryForm() : _buildPickupContent(),
                const SizedBox(height: 24),
                _buildNoteField(),
                const SizedBox(height: 24),
                _buildPriceSummary(subtotal, deliveryFee, widget.discountAmount, total),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
        if (_isSuccessPageVisible)
          _buildSuccessfullPage(context, total),
      ],
    );
  }

  // --- WIDGET COMPONENTS ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bgColor,
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
      title: const Text(
        "Thanh toán",
        style: TextStyle(
          fontFamily: 'GoogleSans',
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildDeliveryTabs() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _buildTabItem("Giao hàng", _isDelivery),
          _buildTabItem("Đến lấy", !_isDelivery),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isDelivery = (label == "Giao hàng")),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(35),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'GoogleSans',
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductListPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mô tả sản phẩm",
          style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildWhiteCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(15),
            itemCount: widget.cartItems.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 20, color: Color(0xFFE5E5EA)),
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];
              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.product.imageUrl,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 65, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Size: ${item.selectedSize} • Đá: ${item.selectedIce} • ${item.selectedSweetness}",
                          style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.grey, fontSize: 11),
                        ),
                        if (item.selectedToppings.isNotEmpty)
                          Text(
                            "Topping: ${item.selectedToppings.join(', ')}",
                            style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.grey, fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${_formatCurrency(item.itemPrice * item.quantity)}đ",
                        style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "x${item.quantity}",
                        style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Thông tin giao hàng"),
        _buildWhiteCard(
          child: Column(
            children: [
              _buildDetailItem(
                icon: Icons.location_on_rounded,
                title: "Địa chỉ nhận hàng",
                subtitle: _selectedAddress != null
                    ? "${_selectedAddress!['address']}"
                    : "Chọn địa chỉ...",
                onTap: _pickAddress,
              ),
              _buildDivider(),
              _buildDetailItem(
                icon: Icons.access_time_rounded,
                title: "Thời gian giao hàng",
                subtitle: "15 - 20 phút",
                onTap: () {},
              ),
              _buildDivider(),
              _buildDetailItem(
                icon: Icons.phone_rounded,
                title: "Người nhận",
                subtitle: _selectedAddress != null
                    ? "${_selectedAddress!['name']} • ${_selectedAddress!['phone']}"
                    : "Bấm để thêm liên lạc",
                onTap: _pickAddress,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Phương thức thanh toán",
          style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // 🔥 ĐÃ SỬA: Danh sách thanh toán hiển thị bằng Expanded để chia đều khoảng cách
        Row(
          children: [
            Expanded(child: _buildPaymentOption(index: 0, icon: Icons.payments_rounded, label: "Tiền mặt")),
            const SizedBox(width: 10),
            Expanded(child: _buildPaymentOption(index: 1, url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1280px-Mastercard-logo.svg.png')),
            const SizedBox(width: 10),
            Expanded(child: _buildPaymentOption(index: 2, url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/1200px-PayPal.svg.png')),
            const SizedBox(width: 10),
            Expanded(child: _buildPaymentOption(index: 3, icon: Icons.credit_card_rounded)), // Icon thẻ tín dụng
          ],
        ),

        if (_selectedPaymentIndex != 0) ...[
          const SizedBox(height: 16),
          _buildCreditCard(),
        ],
      ],
    );
  }

  Widget _buildPickupContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Chọn cửa hàng", onEdit: _pickStore),
        _buildStoreCard(
          name: _selectedStore?['name'] ?? "BrewGo - Quận 1",
          address: _selectedStore?['address'] ?? "123 Lê Lợi, P. Bến Thành, Q.1",
          distance: _selectedStore?['distance'] ?? "0.8 km",
          time: "10-15 min",
          isSelected: true,
        ),
        _buildSectionTitle("Chi tiết lấy hàng"),
        _buildWhiteCard(
          child: Column(
            children: [
              _buildDetailItem(
                icon: Icons.person_rounded,
                title: "Người đến lấy hàng",
                subtitle: _pickupPerson,
                onTap: _showEditPickupPerson,
              ),
              _buildDivider(),
              _buildDetailItem(
                icon: Icons.timer_rounded,
                title: "Dự kiến lấy hàng",
                subtitle: "Hôm nay, 18:30 PM",
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Phương thức thanh toán",
          style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(child: _buildPaymentOption(index: 0, icon: Icons.payments_rounded, label: "Tiền mặt")),
            const SizedBox(width: 10),
            Expanded(child: _buildPaymentOption(index: 1, url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1280px-Mastercard-logo.svg.png')),
            const SizedBox(width: 10),
            Expanded(child: _buildPaymentOption(index: 2, url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/1200px-PayPal.svg.png')),
            const SizedBox(width: 10),
            Expanded(child: _buildPaymentOption(index: 3, icon: Icons.credit_card_rounded)),
          ],
        ),

        if (_selectedPaymentIndex != 0) ...[
          const SizedBox(height: 16),
          _buildCreditCard(),
        ],
      ],
    );
  }

  // 🔥 WIDGET: Ô CHỌN PHƯƠNG THỨC THANH TOÁN (ĐƯỢC THIẾT KẾ LẠI)
  Widget _buildPaymentOption({
    required int index,
    String? url,
    IconData? icon,
    String? label,
  }) {
    bool isSelected = _selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64, // Đủ cao để chứa icon và chữ
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: label != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: isSelected ? _primaryColor : Colors.grey.shade600),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(fontFamily: 'GoogleSans', fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? _primaryColor : Colors.grey.shade600)),
                  ],
                )
              : url != null && url.isNotEmpty
                  ? Image.network(url, width: 36, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.payment, color: Colors.grey.shade600))
                  : Icon(icon, size: 28, color: isSelected ? _primaryColor : Colors.black87),
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: Icon(Icons.edit_note, size: 20, color: _primaryColor),
              label: Text("Edit", style: TextStyle(fontFamily: 'GoogleSans', color: _primaryColor)),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreCard({
    required String name,
    required String address,
    required String distance,
    required String time,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: AppColors.successDark, width: 1.5) : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.successDark, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(address, style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.successDark),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.black87, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(trailingText, style: TextStyle(fontFamily: 'GoogleSans', color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14))
            else
              const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildWhiteCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _buildDivider() => const Divider(height: 1, indent: 56, color: Color(0xFFE5E5EA), thickness: 1);

  Widget _buildCreditCard() {
    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF333333), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CREDIT CARD", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.white70, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
              const Text("VISA", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Icon(Icons.memory_rounded, color: Colors.white70, size: 40),
          const Text(
            "••••  ••••  ••••  3456",
            style: TextStyle(fontFamily: 'GoogleSans', color: Colors.white, fontSize: 22, letterSpacing: 2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CARDHOLDER NAME", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.white70, fontSize: 11, letterSpacing: 1)),
              Row(
                children: [
                  CircleAvatar(radius: 8, backgroundColor: Colors.red.withOpacity(0.8)),
                  Transform.translate(offset: const Offset(-6, 0), child: const CircleAvatar(radius: 8, backgroundColor: Colors.orange)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ghi chú đơn hàng",
          style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 2,
          style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Ví dụ: "Giao giờ hành chính", "Đến nơi gọi điện"...',
            hintStyle: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black38, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.2)),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(double subtotal, double deliveryFee, double discountAmount, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Chi tiết thanh toán",
          style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _priceRow("Tạm tính", "${_formatCurrency(subtotal)}đ"),
              const SizedBox(height: 14),
              _priceRow("Phí ship", "${_formatCurrency(deliveryFee)}đ"),
              if (discountAmount > 0) ...[
                const SizedBox(height: 14),
                _priceRow("Giảm giá", "- ${_formatCurrency(discountAmount)}đ", isDiscount: true),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFE5E5EA), thickness: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tổng cộng", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(
                    "${_formatCurrency(total)}đ",
                    style: TextStyle(fontFamily: 'GoogleSans', fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: 'GoogleSans', color: isDiscount ? Colors.green : Colors.black54, fontSize: 15)),
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

  // 🔥 NÚT BẤM DƯỚI ĐÁY ĐƯỢC BO TRÒN HOÀN TOÀN (PILL-SHAPE)
  Widget _buildBottomButton(double total) {
    return Container(
      margin: EdgeInsets.only(
        left: 16, 
        right: 16, 
        bottom: MediaQuery.of(context).padding.bottom + 16
      ),
      padding: const EdgeInsets.all(6),
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), 
        border: Border.all(color: Colors.grey.shade200, width: 1), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
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
                    "${_formatCurrency(total)}đ",
                    style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // 🔥 Bắt buộc chọn địa chỉ nếu hình thức là Giao hàng
                  if (_isDelivery && _selectedAddress == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng chọn địa chỉ giao hàng!", style: TextStyle(fontFamily: 'GoogleSans'))),
                    );
                    return;
                  }

                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final currentPhone = auth.currentUser?.id;

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    if (widget.selectedPromo != null && currentPhone != null) {
                      await completePayment(widget.selectedPromo!.id, currentPhone);
                    }
                    
                    // 🔥 LƯU ĐƠN HÀNG VÀO FIRESTORE
                    if (currentPhone != null) {
                      final orderRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentPhone)
                          .collection('orders')
                          .doc();

                      await orderRef.set({
                        'orderId': orderRef.id,
                        'createdAt': FieldValue.serverTimestamp(),
                        'items': widget.cartItems.map((item) => {
                          'productId': item.product.id,
                          'name': item.product.name,
                          'imageUrl': item.product.imageUrl,
                          'price': item.itemPrice,
                          'quantity': item.quantity,
                          'size': item.selectedSize,
                          'ice': item.selectedIce,
                          'sweetness': item.selectedSweetness,
                          'toppings': item.selectedToppings,
                        }).toList(),
                        'totalAmount': total,
                        'subtotal': widget.cartItems.fold(0.0, (sum, item) => sum + (item.itemPrice * item.quantity)),
                        'deliveryFee': _isDelivery ? 15000.0 : 0.0,
                        'discountAmount': widget.discountAmount,
                        'status': 'Chờ xác nhận',
                        'isDelivery': _isDelivery,
                        'note': _noteController.text,
                      });
                    }

                    if (!mounted) return;
                    Navigator.pop(context); // Tắt Loading

                    // 🔥 Xóa giỏ hàng sau khi đặt hàng thành công
                    Provider.of<CartProvider>(context, listen: false).clearCart();

                    setState(() {
                      _isSuccessPageVisible = true; // Hiện trang thành công ngay lập tức
                    });
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi thanh toán: $e")));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), 
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Đặt hàng",
                  style: TextStyle(fontFamily: 'GoogleSans', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === TRANG THÀNH CÔNG (SUCCESS PAGE) ===
  Widget _buildSuccessfullPage(BuildContext context, double totalAmount) {
    double deliveryFee = _isDelivery ? 15000.0 : 0.0;
    double subtotal = widget.cartItems.fold(0.0, (sum, item) => sum + (item.itemPrice * item.quantity));

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: _bgColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _primaryColor.withOpacity(0.2), shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _primaryColor,
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Thanh toán thành công!",
                  style: TextStyle(fontFamily: 'GoogleSans', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "Bạn đã thanh toán ${_formatCurrency(totalAmount)}đ",
                  style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildTransactionDetailRow("Tạm tính", "${_formatCurrency(subtotal)}đ"),
                      const SizedBox(height: 16),
                      _buildTransactionDetailRow("Phí giao hàng", "${_formatCurrency(deliveryFee)}đ"),
                      if (widget.discountAmount > 0) ...[
                        const SizedBox(height: 16),
                        _buildTransactionDetailRow("Giảm giá", "- ${_formatCurrency(widget.discountAmount)}đ"),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFE5E5EA)),
                      ),
                      _buildTransactionDetailRow("Tổng cộng", "${_formatCurrency(totalAmount)}đ", isTotal: true),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Quay về trang chủ rồi push đè lên trang Đơn hàng
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor, 
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text(
                      "THEO DÕI ĐƠN HÀNG",
                      style: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    // 🔥 Bỏ từ khóa 'const' ở đây vì _primaryColor không phải là hằng số
                    child: Text(
                      "VỀ TRANG CHỦ",
                      style: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: 'GoogleSans', color: isTotal ? Colors.black87 : Colors.black54, fontSize: 15, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? _primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}