import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

// Biến màu chủ đạo dùng chung cho Admin
const Color _adminPrimary = AppColors.successGreen;

// Hỗ trợ format tiền tệ
String _formatCurrency(double amount) {
  final format = NumberFormat("#,##0", "vi_VN");
  return "${format.format(amount)}đ";
}

// =========================================================================
// 1. DASHBOARD TAB (TỔNG QUAN)
// =========================================================================
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  Future<Map<String, int>> _getStats() async {
    final db = FirebaseFirestore.instance;
    final users = await db.collection('users').count().get();
    final products = await db.collection('products').count().get();
    final orders = await db.collectionGroup('orders').count().get();
    final categories = await db.collection('categories').count().get();

    return {
      'users': users.count ?? 0,
      'products': products.count ?? 0,
      'orders': orders.count ?? 0,
      'categories': categories.count ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tổng quan hệ thống", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard("Doanh thu", "Chưa có data", Icons.attach_money, Colors.orange),
                    _buildStatCard("Đơn hàng", "${stats['orders']}", Icons.receipt_long, Colors.blue),
                    _buildStatCard("Sản phẩm", "${stats['products']}", Icons.coffee, _adminPrimary),
                    _buildStatCard("Người dùng", "${stats['users']}", Icons.people, Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// =========================================================================
// 2. CATEGORIES TAB (QUẢN LÝ DANH MỤC)
// =========================================================================
class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  void _deleteCategory(BuildContext context, String id) {
    FirebaseFirestore.instance.collection('categories').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(data['imageUrl'] ?? '')),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(context, docs[index].id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBright,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm danh mục", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCategoryDialog(context),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thêm Danh Mục", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên danh mục (VD: Cà phê)")),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Mô tả")),
            TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: "Link hình ảnh (URL)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBright),
            onPressed: () {
              if (nameCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên danh mục')));
                return;
              }
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              FirebaseFirestore.instance.collection('categories').doc(id).set({
                'id': id, 
                'name': nameCtrl.text, 
                'description': descCtrl.text, 
                'imageUrl': imgCtrl.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm danh mục')));
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// =========================================================================
// 3. PRODUCTS TAB (QUẢN LÝ SẢN PHẨM)
// =========================================================================
class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  void _deleteProduct(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa sản phẩm này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(id).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm')));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("Chưa có sản phẩm nào"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bool showOnHome = data['showOnHome'] ?? true;
              final bool isPopular = data['isPopular'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // 🔥 CHỨC NĂNG CHỈNH SỬA: Truyền data hiện tại vào form
                    showDialog(
                      context: context,
                      builder: (context) => AddProductDialog(productData: data),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Hình ảnh
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imageUrl'] ?? '', 
                            width: 60, height: 60, fit: BoxFit.cover, 
                            errorBuilder: (c,e,s) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey))
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Thông tin
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(_formatCurrency((data['price'] ?? 0).toDouble()), style: const TextStyle(color: _adminPrimary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              // Thẻ trạng thái hiển thị
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildBadge(showOnHome ? "Trang chủ" : "Chỉ hiện ở Menu", showOnHome ? Colors.blue : Colors.grey),
                                  if (showOnHome) 
                                    _buildBadge(isPopular ? "Best Seller" : "Dành cho bạn", isPopular ? Colors.orange : Colors.purple),
                                ],
                              )
                            ],
                          ),
                        ),
                        // Nút Xóa
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteProduct(context, docs[index].id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBright,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm sản phẩm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddProductDialog(),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

// =========================================================================
// WIDGET: FORM THÊM / SỬA SẢN PHẨM 
// =========================================================================
class AddProductDialog extends StatefulWidget {
  final Map<String, dynamic>? productData; // Nếu có dữ liệu là Chỉnh sửa, nếu null là Thêm mới

  const AddProductDialog({super.key, this.productData});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  // Trạng thái hiển thị
  bool _showOnHome = true;
  bool _isPopular = false; // Tương đương "Best Seller"
  bool _isRecommended = true; // Tương đương "Dành cho bạn"

  bool get _isEditing => widget.productData != null;

  @override
  void initState() {
    super.initState();
    // Nếu là chế độ CHỈNH SỬA, nạp dữ liệu cũ vào các controller
    if (_isEditing) {
      _nameCtrl.text = widget.productData!['name'] ?? '';
      _priceCtrl.text = (widget.productData!['price'] ?? 0).toString();
      _imgCtrl.text = widget.productData!['imageUrl'] ?? '';
      _descCtrl.text = widget.productData!['description'] ?? '';
      
      _showOnHome = widget.productData!['showOnHome'] ?? true;
      _isPopular = widget.productData!['isPopular'] ?? false;
      _isRecommended = !_isPopular; // Nếu không phải Best Seller thì nằm ở Dành cho bạn
    }
    
    _fetchCategories();
  }

  // Tải danh sách Danh mục từ Firebase
  Future<void> _fetchCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = snap.docs.map((doc) => {'id': doc.id, 'name': doc['name']}).toList();
        
        if (_categories.isNotEmpty) {
          // Gán category id cũ nếu đang edit, hoặc gán mặc định item đầu tiên
          if (_isEditing && _categories.any((c) => c['id'] == widget.productData!['categoryId'])) {
            _selectedCategoryId = widget.productData!['categoryId'];
          } else {
            _selectedCategoryId = _categories.first['id'];
          }
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  void _saveProduct() {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền tên, giá và chọn danh mục")));
      return;
    }

    final id = _isEditing ? widget.productData!['id'] : DateTime.now().millisecondsSinceEpoch.toString();
    
    final Map<String, dynamic> dataToSave = {
      'id': id,
      'name': _nameCtrl.text.trim(),
      'price': int.tryParse(_priceCtrl.text.trim().replaceAll('.', '')) ?? 0,
      'imageUrl': _imgCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'categoryId': _selectedCategoryId,
      'showOnHome': _showOnHome,
      'isPopular': _isPopular,
    };

    if (_isEditing) {
      // CẬP NHẬT SẢN PHẨM CŨ
      FirebaseFirestore.instance.collection('products').doc(id).update(dataToSave);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật sản phẩm!")));
    } else {
      // THÊM SẢN PHẨM MỚI
      dataToSave['rating'] = 5.0; // Đánh giá mặc định
      FirebaseFirestore.instance.collection('products').doc(id).set(dataToSave);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm sản phẩm thành công!")));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? "Chỉnh sửa Sản Phẩm" : "Thêm Sản Phẩm Mới", style: const TextStyle(fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CHỌN DANH MỤC
              if (_isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else if (_categories.isEmpty)
                const Text("Vui lòng tạo Danh mục trước!", style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: "Thuộc danh mục", border: OutlineInputBorder()),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['id'],
                      child: Text(cat['name']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
              const SizedBox(height: 16),

              // 2. THÔNG TIN CƠ BẢN
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Tên sản phẩm", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá tiền (VNĐ)", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _imgCtrl, decoration: const InputDecoration(labelText: "Link hình ảnh (URL)", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Mô tả sản phẩm", border: OutlineInputBorder())),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),

              // 3. ĐIỀU KHIỂN VỊ TRÍ HIỂN THỊ
              const Text("Vị trí hiển thị trên App", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: _adminPrimary,
                title: const Text("Hiển thị trên Trang chủ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("Tắt nếu món chỉ bán trong Menu", style: TextStyle(fontSize: 12)),
                value: _showOnHome,
                onChanged: (val) {
                  setState(() {
                    _showOnHome = val;
                    if (!val) {
                      _isPopular = false;
                      _isRecommended = false;
                    } else {
                      _isRecommended = true; // Mặc định bật lại thì cho vào Dành cho bạn
                    }
                  });
                },
              ),
              
              // CÔNG TẮC: BEST SELLER
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 16),
                activeColor: Colors.orange,
                title: const Text("Mục: Best Seller", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                value: _isPopular,
                onChanged: _showOnHome ? (val) {
                  setState(() {
                    _isPopular = val;
                    if (val) _isRecommended = false; // Tự động loại trừ
                  });
                } : null, 
              ),

              // CÔNG TẮC: DÀNH CHO BẠN
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 16),
                activeColor: Colors.purple,
                title: const Text("Mục: Dành cho bạn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                value: _isRecommended,
                onChanged: _showOnHome ? (val) {
                  setState(() {
                    _isRecommended = val;
                    if (val) _isPopular = false; // Tự động loại trừ
                  });
                } : null, 
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBright),
          onPressed: _categories.isEmpty ? null : _saveProduct,
          child: Text(_isEditing ? "Cập nhật" : "Lưu sản phẩm", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}

// =========================================================================
// 4. ORDERS TAB (QUẢN LÝ ĐƠN HÀNG)
// =========================================================================
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("Chưa có đơn hàng nào"));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Chờ xác nhận';

            return Card(
              child: ExpansionTile(
                leading: const Icon(Icons.receipt, color: _adminPrimary),
                title: Text("Đơn hàng: #${docs[index].id.substring(0, 8)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Tổng: ${_formatCurrency((data['totalAmount'] ?? 0).toDouble())}"),
                trailing: _buildStatusBadge(status),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("Cập nhật trạng thái:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Chờ xác nhận', 'Đang chuẩn bị', 'Đang giao hàng', 'Hoàn thành', 'Đã hủy'].map((s) {
                            return ChoiceChip(
                              label: Text(s),
                              selected: status == s,
                              selectedColor: _adminPrimary.withOpacity(0.3),
                              onSelected: (selected) {
                                if (selected) docs[index].reference.update({'status': s});
                              },
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Đang chuẩn bị') color = Colors.blue;
    if (status == 'Đang giao hàng') color = Colors.purple;
    if (status == 'Hoàn thành') color = Colors.green;
    if (status == 'Đã hủy') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// =========================================================================
// 5. USERS TAB (QUẢN LÝ NGƯỜI DÙNG)
// =========================================================================
class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final role = data['role'] ?? 'user';
            
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                  child: Icon(role == 'admin' ? Icons.admin_panel_settings : Icons.person, color: role == 'admin' ? Colors.red : Colors.blue),
                ),
                title: Text(data['name'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['email'] ?? data['phone'] ?? ''),
                trailing: DropdownButton<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (newRole) {
                    // Cấm tự hạ quyền của chính mình
                    if (data['email'] == 'brewgo@admin.com') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể đổi quyền của Admin gốc!')));
                      return;
                    }
                    if (newRole != null) {
                      FirebaseFirestore.instance.collection('users').doc(docs[index].id).update({'role': newRole});
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =========================================================================
// CÁC TAB KHÁC (Chờ phát triển)
// =========================================================================
class PromotionsTab extends StatelessWidget { const PromotionsTab({super.key}); @override Widget build(BuildContext context) => const Center(child: Text("Quản lý Mã giảm giá (Voucher)")); }
class ReviewsTab extends StatelessWidget { const ReviewsTab({super.key}); @override Widget build(BuildContext context) => const Center(child: Text("Đánh giá từ khách hàng")); }
class SettingsTab extends StatelessWidget { const SettingsTab({super.key}); @override Widget build(BuildContext context) => const Center(child: Text("Cài đặt cấu hình cửa hàng")); }