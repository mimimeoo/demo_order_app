import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Đảm bảo các đường dẫn này chính xác với project của bạn
import '../providers/auth_provider.dart';
import '../models/promo_model.dart';
import '../models/cart_model.dart';
import 'address_screen.dart';
import 'store_selection_screen.dart';

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
  final Color _primaryColor = AppColors.primaryBright;
  final Color _bgColor = AppColors.bgLighter;

  bool _isDelivery = true;
  bool _isSuccessPageVisible =
      false; // Biến điều khiển hiển thị trang thành công
  String _pickupPerson = "Vui lòng nhập tên của bạn";
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedStore;

  // Format tiền tệ
  String _formatCurrency(double amount) {
    final format = NumberFormat("#,##0", "vi_VN");
    return format.format(amount);
  }

  // Logic xử lý Firebase
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Người nhận hàng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Nhập tên người nhận...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
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
                backgroundColor: AppColors.primaryBright,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "Xác nhận",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _bgColor,
          appBar: _buildAppBar(context),
          bottomNavigationBar: _buildBottomButton(widget.finalTotal),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildDeliveryTabs(),
                const SizedBox(height: 20),
                _buildProductListPreview(),
                const SizedBox(height: 20),
                _isDelivery ? _buildDeliveryForm() : _buildPickupContent(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
        // Hiển thị trang thành công khi biến _isSuccessPageVisible là true
        if (_isSuccessPageVisible)
          _buildSuccessfullPage(context, widget.finalTotal),
      ],
    );
  }

  // --- WIDGET COMPONENTS ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 70,
      leading: _buildRoundNavButton(
        Icons.arrow_back,
        () => Navigator.pop(context),
      ),
      title: const Text(
        "Checkout",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        _buildRoundNavButton(Icons.more_vert, () {}),
        const SizedBox(width: 10),
      ],
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        _buildWhiteCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(15),
            itemCount: widget.cartItems.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 20, color: AppColors.dividerLight),
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
                          const Icon(Icons.image_not_supported, size: 65),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Size: ${item.selectedSize} | Đá: ${item.selectedIce} | Đường: ${item.selectedSweetness}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        if (item.selectedToppings.isNotEmpty)
                          Text(
                            "Topping: ${item.selectedToppings.join(', ')}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${_formatCurrency(item.itemPrice * item.quantity)}đ",
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "x${item.quantity}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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

  Widget _buildCreditCard() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [AppColors.orangeMedium, AppColors.orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeDark.withValues(alpha: 0.3),
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
              const Text(
                "CARD TYPE",
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
              const Text(
                "VISA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Icon(Icons.card_membership, color: AppColors.goldenLight, size: 45),
          const Text(
            "1234  5678  9012  3456",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CARDHOLDER NAME",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                  ),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: AppColors.primaryBright,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ElevatedButton(
        onPressed: () async {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final currentPhone = auth.currentUser?.id;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          try {
            if (widget.selectedPromo != null && currentPhone != null) {
              await completePayment(widget.selectedPromo!.id, currentPhone);
            }
            if (!mounted) return;
            Navigator.pop(context); // Tắt Loading

            setState(() {
              _isSuccessPageVisible = true; // Hiện trang thành công
            });
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Lỗi thanh toán: $e")));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: _primaryColor.withValues(alpha: 0.4),
        ),
        child: const Text(
          "Xác Nhận Thanh Toán",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
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
                icon: Icons.home_outlined,
                title: "Địa chỉ giao hàng",
                subtitle: _selectedAddress != null
                    ? "${_selectedAddress!['address']}"
                    : "Vui lòng chọn địa chỉ giao hàng",
                onTap: _pickAddress,
              ),
              _buildDivider(),
              _buildDetailItem(
                icon: Icons.access_time,
                title: "Thời gian giao hàng",
                subtitle: "15 - 20 min",
                onTap: () {},
              ),
              _buildDivider(),
              _buildDetailItem(
                icon: Icons.phone_outlined,
                title: "Số điện thoại liên hệ",
                subtitle: _selectedAddress != null
                    ? "${_selectedAddress!['name']} • ${_selectedAddress!['phone']}"
                    : "Bấm để thêm thông tin liên lạc",
                onTap: _pickAddress,
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          "Phương thức thanh toán",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPaymentLogoItem(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1280px-Mastercard-logo.svg.png',
              isSelected: true,
            ),
            _buildPaymentLogoItem(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/1200px-PayPal.svg.png',
            ),
            _buildPaymentLogoItem('', isIcon: true, icon: Icons.apple),
            _buildPaymentLogoItem(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google__G__Logo.svg/2048px-Google__G__Logo.svg.png',
            ),
          ],
        ),
        const SizedBox(height: 25),
        _buildCreditCard(),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "TỔNG CỘNG",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: "${_formatCurrency(widget.finalTotal)} "),
                  const TextSpan(
                    text: "đ",
                    style: TextStyle(color: Colors.black38, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentLogoItem(
    String url, {
    bool isSelected = false,
    bool isIcon = false,
    IconData? icon,
  }) {
    return Container(
      width: 70,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.black87 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Center(
        child: isIcon
            ? Icon(icon, size: 28)
            : (url.isNotEmpty
                  ? Image.network(
                      url,
                      width: 35,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(Icons.payment),
                    )
                  : const Icon(Icons.payment)),
      ),
    );
  }

  Widget _buildPickupContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Chọn cửa hàng", onEdit: _pickStore),
        _buildStoreCard(
          name: _selectedStore?['name'] ?? "BrewGo - Quận 1",
          address:
              _selectedStore?['address'] ?? "123 Lê Lợi, P. Bến Thành, Q.1",
          distance: _selectedStore?['distance'] ?? "0.8 km",
          time: "10-15 min",
          isSelected: true,
        ),
        _buildSectionTitle("Chi tiết lấy hàng"),
        _buildWhiteCard(
          child: Column(
            children: [
              _buildDetailItem(
                icon: Icons.person_pin_circle_outlined,
                title: "Người đến lấy hàng",
                subtitle: _pickupPerson,
                onTap: _showEditPickupPerson,
              ),
              _buildDivider(),
              _buildDetailItem(
                icon: Icons.timer_outlined,
                title: "Dự kiến thời gian lấy hàng",
                subtitle: "Today, 18:30 PM",
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          "Phương thức thanh toán",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPaymentLogoItem(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1280px-Mastercard-logo.svg.png',
              isSelected: true,
            ),
            _buildPaymentLogoItem(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/1200px-PayPal.svg.png',
            ),
            _buildPaymentLogoItem('', isIcon: true, icon: Icons.apple),
            _buildPaymentLogoItem(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google__G__Logo.svg/2048px-Google__G__Logo.svg.png',
            ),
          ],
        ),
        const SizedBox(height: 25),
        _buildCreditCard(),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "TỔNG CỘNG",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: "${_formatCurrency(widget.finalTotal)} "),
                  const TextSpan(
                    text: "đ",
                    style: TextStyle(color: Colors.black38, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- UI HELPERS ---

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: Icon(Icons.edit_note, size: 20, color: _primaryColor),
            label: Text("Edit", style: TextStyle(color: _primaryColor)),
          ),
      ],
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
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isSelected
            ? Border.all(color: AppColors.successDark, width: 2)
            : null,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: AppColors.successDark,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  address,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
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
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }

  Widget _buildRoundNavButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildWhiteCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: child,
  );

  Widget _buildDivider() =>
      const Divider(height: 1, indent: 60, color: AppColors.divider);
  Widget _buildSuccessfullPage(BuildContext context, double totalAmount) {
    const feeAmount = 15000.0;
    final amount = totalAmount - feeAmount;

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.yellowLight, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // Thêm SafeArea để tránh tai thỏ
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              // CĂN GIỮA TOÀN BỘ THEO CHIỀU DỌC
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSuccessIcon(),
                const SizedBox(height: 30),
                const Text(
                  "Thanh toán thành công!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Bạn đã thanh toán ${_formatCurrency(totalAmount)}đ",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),
                _buildTransactionDetailCard(amount, feeAmount, totalAmount),
                const SizedBox(height: 30),

                // Transfer Details Dropdown
                InkWell(
                  // Dùng InkWell để có thể nhấn vào hàng này
                  onTap: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Transfer Details",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60), // Khoảng cách giữa nội dung và nút
                _buildBottomActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
 Widget _buildSuccessIcon() {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: const BoxDecoration(color: AppColors.orangeLight, shape: BoxShape.circle),

      child: Container(

        padding: const EdgeInsets.all(15),

        decoration: const BoxDecoration(color: AppColors.orangeMedium, shape: BoxShape.circle),

        child: const CircleAvatar(

          radius: 15,

          backgroundColor: AppColors.orangeDark,

        ),

      ),

    );

  }



  Widget _buildTransactionDetailCard(double amount, double fee, double total) {

    return Container(

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 15,

            offset: const Offset(0, 5),

          ),

        ],

      ),

      child: Column(

        children: [

          _buildTransactionDetailRow("Thành tiền", "${_formatCurrency(amount)}đ"),

          const SizedBox(height: 15),

          _buildTransactionDetailRow("Phí giao hàng", "${_formatCurrency(fee)}đ"),

          const SizedBox(height: 15),

          _buildTransactionDetailRow("Tổng số tiền", "${_formatCurrency(total)}đ", isTotal: true),

          const SizedBox(height: 15),

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              const Text("Trạng thái", style: TextStyle(color: Colors.black54, fontSize: 14)),

              const Row(

                children: [

                  Icon(Icons.check, color: Colors.green, size: 16),

                  SizedBox(width: 5),

                  Text("Hoàn tất", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),

                ],

              ),

            ],

          ),

        ],

      ),

    );

  }

  Widget _buildTransactionDetailRow(String label, String value, {bool isTotal = false}) {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),

        Text(

          value,

          style: TextStyle(

            fontSize: isTotal ? 16 : 14,

            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,

            color: Colors.black87,

          ),

        ),

      ],

    );

  }


  Widget _buildBottomActionButtons(BuildContext context) {
    return Row(
      children: [
        // Nút Back Home
        Expanded(
          flex: 4,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _primaryColor, // Hãy đảm bảo biến này đã được định nghĩa
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Back Home",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 15),

        // Nút Share (Hình tròn bên phải)
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: AppColors.bgLightest, // Màu xám nhạt như trong ảnh
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chức năng chia sẻ...")),
              );
            },
            icon: Transform.rotate(
              angle: 0.7, // Xoay icon mũi tên theo hướng chéo
              child: const Icon(
                Icons.north_east,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
