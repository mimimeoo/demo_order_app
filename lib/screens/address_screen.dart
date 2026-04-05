import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // Đổi sang dùng màu chủ đạo (thường là màu Cam theo ảnh mẫu)
  final Color _primaryColor = AppColors.primary;
  final Color _bgColor = const Color(0xFFF4F4F5); // Nền xám nhạt đồng bộ toàn app

  IconData _getIcon(String title) {
    String t = title.toLowerCase();
    if (t.contains("công ty") || t.contains("văn phòng")) return Icons.business_rounded;
    return Icons.home_rounded;
  }

  // --- BIẾN LƯU DỮ LIỆU API ---
  List<dynamic> _provincesList = [];
  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations(); 
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/?depth=3'));
      
      if (response.statusCode == 200) {
        final decodedData = utf8.decode(response.bodyBytes);
        if (mounted) {
          setState(() {
            _provincesList = json.decode(decodedData);
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải API địa giới: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  // =======================================================
  // LOGIC FIREBASE (GIỮ NGUYÊN)
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
  // BOTTOM SHEET: FORM THÊM / SỬA ĐỊA CHỈ (GIỮ NGUYÊN LOGIC, CHỈNH UI)
  // =======================================================
  void _showAddressForm(String userId, List<Map<String, dynamic>> currentList, {String? id}) {
    final isEditing = id != null;
    final addressData = isEditing ? currentList.firstWhere((a) => a['id'] == id) : null;

    final titleController = TextEditingController(text: addressData?['title'] ?? '');
    final nameController = TextEditingController(text: addressData?['name'] ?? '');
    final phoneController = TextEditingController(text: addressData?['phone'] ?? '');
    final addressController = TextEditingController();
    bool isDefault = addressData?['isDefault'] ?? false;

    String? selectedCity;
    String? selectedDistrict;
    String? selectedWard;

    if (isEditing && addressData?['address'] != null) {
      String fullAddr = addressData!['address'];
      List<String> parts = fullAddr.split(', ');
      if (parts.length >= 4) {
        addressController.text = parts.sublist(0, parts.length - 3).join(', ');
        selectedWard = parts[parts.length - 3];
        selectedDistrict = parts[parts.length - 2];
        selectedCity = parts[parts.length - 1];
      } else {
        addressController.text = fullAddr; 
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            List<String> cityNames = _provincesList.map((p) => p['name'].toString()).toList();
            if (selectedCity != null && !cityNames.contains(selectedCity)) selectedCity = null;

            List<String> districtNames = [];
            if (selectedCity != null) {
              final cityObj = _provincesList.firstWhere((p) => p['name'] == selectedCity, orElse: () => null);
              if (cityObj != null && cityObj['districts'] != null) {
                districtNames = (cityObj['districts'] as List).map((d) => d['name'].toString()).toList();
              }
            }
            if (selectedDistrict != null && !districtNames.contains(selectedDistrict)) selectedDistrict = null;

            List<String> wardNames = [];
            if (selectedCity != null && selectedDistrict != null) {
              final cityObj = _provincesList.firstWhere((p) => p['name'] == selectedCity, orElse: () => null);
              if (cityObj != null && cityObj['districts'] != null) {
                final districtObj = (cityObj['districts'] as List).firstWhere((d) => d['name'] == selectedDistrict, orElse: () => null);
                if (districtObj != null && districtObj['wards'] != null) {
                  wardNames = (districtObj['wards'] as List).map((w) => w['name'].toString()).toList();
                }
              }
            }
            if (selectedWard != null && !wardNames.contains(selectedWard)) selectedWard = null;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                    style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Tên gợi nhớ (VD: Nhà riêng, Công ty)"),
                          _buildTextField(titleController, "Nhập tên gợi nhớ"),
                          _buildInputLabel("Tên người nhận"),
                          _buildTextField(nameController, "Nhập họ và tên"),
                          _buildInputLabel("Số điện thoại"),
                          _buildTextField(phoneController, "Nhập số điện thoại", keyboardType: TextInputType.phone),
                          
                          _buildInputLabel("Tỉnh / Thành phố"),
                          _isLoadingLocations 
                            ? const Padding(padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16), child: Text("Đang tải dữ liệu...", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black54)))
                            : _buildDropdown(
                                hint: "Chọn Thành phố",
                                value: selectedCity,
                                items: cityNames,
                                onChanged: (val) => setModalState(() {
                                  selectedCity = val;
                                  selectedDistrict = null;
                                  selectedWard = null;
                                }),
                              ),

                          _buildInputLabel("Quận / Huyện"),
                          _buildDropdown(
                            hint: "Chọn Quận / Huyện",
                            value: selectedDistrict,
                            items: districtNames,
                            onChanged: (val) => setModalState(() {
                              selectedDistrict = val;
                              selectedWard = null;
                            }),
                          ),

                          _buildInputLabel("Phường / Xã"),
                          _buildDropdown(
                            hint: "Chọn Phường / Xã",
                            value: selectedWard,
                            items: wardNames,
                            onChanged: (val) => setModalState(() => selectedWard = val),
                          ),
                          
                          _buildInputLabel("Số nhà, Tên đường"),
                          _buildTextField(addressController, "Nhập số nhà, ngõ, tên đường..."),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Đặt làm mặc định", style: TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.w600, fontSize: 15)),
                              Switch(
                                value: isDefault,
                                activeColor: _primaryColor,
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
                        if (nameController.text.isEmpty || phoneController.text.isEmpty || addressController.text.isEmpty || selectedCity == null || selectedDistrict == null || selectedWard == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin", style: TextStyle(fontFamily: 'GoogleSans'))));
                          return;
                        }
                        
                        final fullAddress = "${addressController.text}, $selectedWard, $selectedDistrict, $selectedCity";
                        final newData = {
                          "title": titleController.text.isNotEmpty ? titleController.text : "Khác",
                          "name": nameController.text,
                          "phone": phoneController.text,
                          "address": fullAddress,
                          "isDefault": isDefault,
                        };
                        _saveAddress(userId, currentList, id: id, newData: newData);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text("Lưu địa chỉ", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
  // GIAO DIỆN CHÍNH TRANG LIST ĐỊA CHỈ
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
      backgroundColor: _bgColor,
      extendBody: true, 
      appBar: AppBar(
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
        title: const Text("Địa chỉ giao hàng", 
          style: TextStyle(fontFamily: 'GoogleSans', color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Center(child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(
                      children: [
                        Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("Bạn chưa có địa chỉ nào", style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, color: Colors.black54)),
                      ],
                    ),
                  )),
                const SizedBox(height: 12),
                _buildMapSection(),
                const SizedBox(height: 120), // Tránh đè Bottom Bar
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
      child: Text(title, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  // 🔥 THẺ ĐỊA CHỈ: Chuẩn UI theo hình ảnh mẫu
  Widget _buildAddressCard(String userId, List<Map<String, dynamic>> currentList, Map<String, dynamic> data) {
    bool isDefault = data['isDefault'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          )
        ],
      ),
     child: InkWell(
      onTap: () {
        Navigator.pop(context, data); 
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon trong vòng tròn nền cam nhạt
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(data['title']), color: _primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(data['title'], style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(width: 8),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.08), 
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _primaryColor.withOpacity(0.4)),
                              ),
                              child: Text("Mặc định", style: TextStyle(fontFamily: 'GoogleSans', color: _primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("${data['name']} • ${data['phone']}", style: const TextStyle(fontFamily: 'GoogleSans', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(data['address'], style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black54, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F5), thickness: 1.5),
          
          // Hàng nút Sửa / Xóa
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _showAddressForm(userId, currentList, id: data['id']),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16))),
                    ),
                    child: const Text("Sửa", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1.5, color: Color(0xFFF4F4F5)),
                Expanded(
                  child: TextButton(
                    onPressed: () => _deleteAddress(userId, data['id'], isDefault),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(16))),
                    ),
                    child: const Text("Xóa", style: TextStyle(fontFamily: 'GoogleSans', color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
     ),
    );
  }

  // 🔥 BOTTOM BAR: Đồng bộ phong cách viên nang lơ lửng
  Widget _buildBottomAction(String userId) {
    return Container(
      margin: EdgeInsets.only(
        left: 16, 
        right: 16, 
        bottom: MediaQuery.of(context).padding.bottom + 16
      ),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showAddressForm(userId, []),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: const Text("Thêm địa chỉ mới", 
            style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  // 🔥 BẢN ĐỒ GIẢ LẬP: Nền xanh nhạt, đường chéo trắng, nút chữ cam
  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Vị trí trên bản đồ"),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Nền màu xanh nhạt bám sát ảnh mẫu
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size.infinite, painter: MapGridPainter()),
              const Padding(
                padding: EdgeInsets.only(bottom: 24), // Đẩy icon map lên xíu để không che nút
                child: Icon(Icons.location_on, color: Colors.redAccent, size: 40),
              ),
              Positioned(
                bottom: 16,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.1),
                  ),
                  child: Text("Chọn từ bản đồ", style: TextStyle(fontFamily: 'GoogleSans', color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
      child: Text(text, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF4F4F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.2)),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontFamily: 'GoogleSans', color: Colors.black38, fontSize: 14)),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item, 
              child: Text(item, style: const TextStyle(fontFamily: 'GoogleSans', fontSize: 15, color: Colors.black87))
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Class vẽ bản đồ giả lập (Vẽ đường chéo mô phỏng hệt ảnh)
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 1.5;
    
    // Vẽ các đường cắt chéo tạo cảm giác đường phố
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.7), paint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width * 0.8, 0), paint);
    canvas.drawLine(Offset(size.width * 0.2, size.height), Offset(size.width, size.height * 0.2), paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}