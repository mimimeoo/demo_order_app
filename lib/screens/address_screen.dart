import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // Bảng màu đồng bộ với CartScreen
  final Color _primaryGreen = AppColors.primaryBright;
  final Color _backgroundColor = AppColors.bgLighter;

  IconData _getIcon(String title) {
    String t = title.toLowerCase();
    if (t.contains("công ty") || t.contains("văn phòng")) return Icons.business_rounded;
    return Icons.home_rounded;
  }

  // =======================================================
  // LOGIC FIREBASE
  // =======================================================
  void _deleteAddress(String userId, String id, bool isDefault) async {
    final collection = FirebaseFirestore.instance.collection('users').doc(userId).collection('addresses');
    await collection.doc(id).delete();
    
    if (isDefault) {
      final remaining = await collection.limit(1).get();
      if (remaining.docs.isNotEmpty) {
        await remaining.docs.first.reference.update({'isDefault': true});
      }
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa địa chỉ")));
  }

  void _saveAddress(String userId, List<Map<String, dynamic>> currentList, {String? id, required Map<String, dynamic> newData}) async {
    final collection = FirebaseFirestore.instance.collection('users').doc(userId).collection('addresses');

    if (currentList.isEmpty) {
      newData['isDefault'] = true;
    } 

    if (newData['isDefault'] == true) {
      final batch = FirebaseFirestore.instance.batch();
      final defaultDocs = await collection.where('isDefault', isEqualTo: true).get();
      for (var doc in defaultDocs.docs) {
        if (doc.id != id) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
      await batch.commit();
    }

    if (id == null) {
      final newDoc = collection.doc();
      newData['id'] = newDoc.id;
      await newDoc.set(newData);
    } else {
      await collection.doc(id).update(newData);
    }
  }

  // =======================================================
  // BOTTOM SHEET: FORM THÊM / SỬA ĐỊA CHỈ (ĐÃ UPDATE UI)
  // =======================================================
  void _showAddressForm(String userId, List<Map<String, dynamic>> currentList, {String? id}) {
    final isEditing = id != null;
    final addressData = isEditing ? currentList.firstWhere((a) => a['id'] == id) : null;

    final titleController = TextEditingController(text: addressData?['title'] ?? '');
    final nameController = TextEditingController(text: addressData?['name'] ?? '');
    final phoneController = TextEditingController(text: addressData?['phone'] ?? '');
    final addressController = TextEditingController(text: addressData?['address'] ?? '');
    bool isDefault = addressData?['isDefault'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 24, right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Text(isEditing ? "Chỉnh sửa địa chỉ" : "Thêm địa chỉ mới", 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Tên gợi nhớ (VD: Nhà riêng, Công ty)"),
                          _buildTextField(titleController, "Nhập tên gợi nhớ"),
                          _buildInputLabel("Tên người nhận"),
                          _buildTextField(nameController, "Nhập họ và tên"),
                          _buildInputLabel("Số điện thoại"),
                          _buildTextField(phoneController, "Nhập số điện thoại", keyboardType: TextInputType.phone),
                          _buildInputLabel("Địa chỉ chi tiết"),
                          _buildTextField(addressController, "Nhập địa chỉ nhận hàng..."),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Đặt làm mặc định", style: TextStyle(fontWeight: FontWeight.w600)),
                              Switch(
                                value: isDefault,
                                activeColor: _primaryGreen,
                                onChanged: (val) => setModalState(() => isDefault = val),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isEmpty || phoneController.text.isEmpty || addressController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin")));
                          return;
                        }
                        final newData = {
                          "title": titleController.text.isNotEmpty ? titleController.text : "Khác",
                          "name": nameController.text,
                          "phone": phoneController.text,
                          "address": addressController.text,
                          "isDefault": isDefault,
                        };
                        _saveAddress(userId, currentList, id: id, newData: newData);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBright,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Lưu địa chỉ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  // =======================================================
  // GIAO DIỆN CHÍNH
  // =======================================================
  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Địa chỉ giao hàng"), backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text("Vui lòng đăng nhập")),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Địa chỉ giao hàng", 
          style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('addresses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final addresses = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

          final defaultAddresses = addresses.where((a) => a['isDefault'] == true).toList();
          final otherAddresses = addresses.where((a) => a['isDefault'] != true).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (defaultAddresses.isNotEmpty) ...[
                  _buildSectionTitle("Địa chỉ mặc định"),
                  ...defaultAddresses.map((addr) => _buildAddressCard(userId, addresses, addr)),
                ],
                if (otherAddresses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionTitle("Địa chỉ khác"),
                  ...otherAddresses.map((addr) => _buildAddressCard(userId, addresses, addr)),
                ],
                if (addresses.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Text("Bạn chưa có địa chỉ nào"),
                  )),
                const SizedBox(height: 20),
                _buildMapSection(),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomAction(userId),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
    );
  }

Widget _buildAddressCard(String userId, List<Map<String, dynamic>> currentList, Map<String, dynamic> data) {
    bool isDefault = data['isDefault'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
     child: InkWell(
      onTap: () {
        // TRUYỀN DỮ LIỆU VỀ: Trả về Map chứa thông tin địa chỉ
        Navigator.pop(context, data); 
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withAlpha(25), // Dùng withAlpha thay cho withOpacity cũ
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIcon(data['title']), color: _primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(data['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Mặc định", style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(data['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text(data['phone'], style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(data['address'], style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddressForm(userId, currentList, id: data['id']),
                    icon: Icon(Icons.edit_outlined, size: 18, color: _primaryGreen),
                    label: Text("Sửa", style: TextStyle(color: _primaryGreen)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteAddress(userId, data['id'], isDefault),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    label: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(String userId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _showAddressForm(userId, []),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text("Thêm địa chỉ mới", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Vị trí trên bản đồ"),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.blueLightBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size.infinite, painter: MapGridPainter()),
              const Icon(Icons.location_on, color: Colors.red, size: 40),
              Positioned(
                bottom: 16,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Chọn từ bản đồ", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.bgLighter,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// Class vẽ bản đồ giả lập
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(150)..strokeWidth = 2.0;
    canvas.drawLine(const Offset(0, 40), Offset(size.width, 80), paint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.7, size.height), paint);
    canvas.drawLine(Offset(0, size.height - 20), Offset(size.width, 10), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}