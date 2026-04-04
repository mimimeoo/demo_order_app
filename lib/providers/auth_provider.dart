import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  AuthProvider() {
    _checkLoginStatus();
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isStaff => _currentUser?.role == 'staff';
  bool get canAccessAdminPanel => isAdmin || isStaff;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // ==========================================
  // 0. TỰ ĐỘNG DUY TRÌ ĐĂNG NHẬP
  // ==========================================
  Future<void> _checkLoginStatus() async {
    User? fbUser = _auth.currentUser;
    if (fbUser != null) {
      await _fetchAndSetUser(fbUser.uid);
    }
    _isLoading = false;
    notifyListeners();
  }

  // ==========================================
  // 1. ĐĂNG NHẬP BẰNG EMAIL HOẶC SỐ ĐIỆN THOẠI
  // ==========================================
  Future<String> login(String emailOrPhone, String password) async {
    _setLoading(true);
    try {
      String email = emailOrPhone.trim();

      // LOGIC ĐẶC BIỆT CHO TÀI KHOẢN ADMIN TEST
      if (email == 'brewgo@admin.com' && password == 'admin123') {
        try {
          UserCredential uc = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          await _fetchAndSetUser(uc.user!.uid);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            UserCredential uc = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            UserModel adminUser = UserModel(
              id: uc.user!.uid,
              displayName: "Admin BrewGo",
              email: email,
              phone: "0000000000",
              role: "admin",
              createdAt: DateTime.now(),
            );
            await _firestore
                .collection('users')
                .doc(adminUser.id)
                .set(adminUser.toMap());
            _currentUser = adminUser;
          } else {
            throw e;
          }
        }
        _setLoading(false);
        return 'success';
      }

      // NẾU NGƯỜI DÙNG NHẬP SỐ ĐIỆN THOẠI (Không có @)
      if (!email.contains('@')) {
        // Tìm email tương ứng với số điện thoại trong Database
        final userQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: email)
            .limit(1)
            .get();
        if (userQuery.docs.isEmpty) {
          _setLoading(false);
          return 'Số điện thoại này chưa được đăng ký!';
        }
        email = userQuery.docs.first.get('email'); // Lấy email để đăng nhập
      }

      // THỰC HIỆN ĐĂNG NHẬP
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _fetchAndSetUser(userCredential.user!.uid);

      _setLoading(false);
      return 'success';
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return 'Tài khoản hoặc mật khẩu không đúng!';
      }
      return e.message ?? 'Đã xảy ra lỗi đăng nhập';
    } catch (e) {
      _setLoading(false);
      return 'Lỗi hệ thống: $e';
    }
  }

  // ==========================================
  // 2. ĐĂNG KÝ (KIỂM TRA TRÙNG EMAIL & SĐT)
  // ==========================================
  Future<String> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    _setLoading(true);
    try {
      // 1. Kiểm tra xem số điện thoại đã tồn tại trong Firestore chưa
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .get();
      if (phoneQuery.docs.isNotEmpty) {
        _setLoading(false);
        return 'Số điện thoại này đã được đăng ký!'; // Chặn đăng ký nếu SĐT bị trùng
      }

      // 2. Tạo tài khoản (Firebase tự động chặn nếu Email bị trùng)
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // 3. Lưu thông tin vào Firestore
      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        displayName: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: 'user',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
      _currentUser = newUser;

      _setLoading(false);
      return 'success';
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'email-already-in-use') return 'Email này đã được đăng ký!';
      if (e.code == 'weak-password')
        return 'Mật khẩu quá yếu, vui lòng nhập ít nhất 6 ký tự!';
      return e.message ?? 'Đã xảy ra lỗi đăng ký';
    } catch (e) {
      _setLoading(false);
      return 'Lỗi hệ thống: $e';
    }
  }

  // ==========================================
  // 3. ĐĂNG XUẤT
  // ==========================================
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ==========================================
  // 4. LẤY DỮ LIỆU USER TỪ FIRESTORE
  // ==========================================
  Future<void> _fetchAndSetUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        // Ép kiểu từ Snapshot vào Model
        _currentUser = UserModel.fromSnapshot(doc);
      } else {
        // Nếu lỡ may Auth có mà Firestore chưa có (tạo mới)
        User? fbUser = _auth.currentUser;
        if (fbUser != null) {
          _currentUser = UserModel(
            id: uid,
            displayName: fbUser.displayName ?? "Người dùng mới",
            email: fbUser.email ?? "",
            phone: fbUser.phoneNumber ?? "",
            role: 'user',
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(uid)
              .set(_currentUser!.toMap());
        }
      }
      notifyListeners(); // Dòng này cực kỳ quan trọng để HomeScreen nhận ra thay đổi
    } catch (e) {
      debugPrint("Lỗi lấy dữ liệu user: $e");
    }
  }

  Future<void> addNewAddress(
    String userId,
    String label,
    String address,
    bool isDefault,
  ) async {
    final addressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses');

    // Nếu người dùng chọn đây là địa chỉ mặc định
    if (isDefault) {
      // Tìm các địa chỉ đang là mặc định cũ và hủy nó đi
      final query = await addressRef.where('isDefault', isEqualTo: true).get();
      for (var doc in query.docs) {
        await doc.reference.update({'isDefault': false});
      }
    }

    // Thêm địa chỉ mới
    await addressRef.add({
      'label': label,
      'fullAddress': address,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(), // Giúp sắp xếp địa chỉ
    });
  }

  Future<void> updateProfile({
  required String displayName, 
  required String email, 
  required String gender,
}) async {
  try {
    // SỬA: Dùng chính cái ID (+84...) mà Model đã nạp lúc đăng nhập
    final String? docId = _currentUser?.id; 

    if (docId == null) {
      debugPrint("Lỗi: Không tìm thấy ID người dùng để update");
      return;
    }

    // 1. Ghi đè lên Firestore
    await _firestore.collection('users').doc(docId).update({
      'displayName': displayName,
      'e-mail': email,   // Khớp với Key trong ảnh
      'gender': gender,
    });

    // 2. Cập nhật "bản sao" trong máy (Local State)
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        email: email,
        gender: gender,
      );
      
      notifyListeners(); // Lệnh này giúp ProfileScreen tự động vẽ lại
      debugPrint("Đã cập nhật thành công cho: $docId");
    }
  } catch (e) {
    debugPrint("Lỗi update: $e");
    rethrow;
  }
}
}
