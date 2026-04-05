import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String? _verificationId;
  String? _pendingPhone;

  UserModel? _currentUser;

  AuthProvider() {
    _checkLoginStatus();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // =======================================================
  // 0. TỰ ĐỘNG DUY TRÌ ĐĂNG NHẬP
  // =======================================================
  Future<void> _checkLoginStatus() async {
    User? fbUser = _auth.currentUser;
    if (fbUser != null) {
      await _fetchAndSetUser(fbUser.uid);
    }
    _isLoading = false;
    notifyListeners();
  }

  // =======================================================
  // 1. GỬI MÃ OTP ĐẾN SỐ ĐIỆN THOẠI
  // =======================================================
  Future<void> verifyPhone(
    String phone, 
    VoidCallback codeSentCallback, 
    ValueChanged<String> errorCallback
  ) async {
    _setLoading(true);
    _pendingPhone = phone; 

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signInWithCredential(credential, errorCallback, (status) {});
      },
      verificationFailed: (FirebaseAuthException e) {
        _setLoading(false);
        errorCallback(e.message ?? 'Lỗi gửi mã OTP. Vui lòng kiểm tra lại số điện thoại.');
      },
      codeSent: (String verificationId, int? resendToken) {
        _setLoading(false);
        _verificationId = verificationId;
        codeSentCallback(); 
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // =======================================================
  // 2. XÁC THỰC MÃ OTP & CHECK USER TỒN TẠI
  // =======================================================
  Future<void> verifyOTP(
    String otp, 
    ValueChanged<String> successCallback, 
    ValueChanged<String> errorCallback
  ) async {
    if (_verificationId == null) {
      errorCallback('Lỗi phiên xác thực. Vui lòng quay lại và thử lại.');
      return;
    }
    _setLoading(true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential, errorCallback, successCallback);
    } on FirebaseAuthException catch (_) {
      _setLoading(false);
      errorCallback('Mã OTP không chính xác hoặc đã hết hạn.');
    }
  }

  Future<void> _signInWithCredential(
    PhoneAuthCredential credential, 
    ValueChanged<String> errorCallback,
    ValueChanged<String> successCallback
  ) async {
    try {
      UserCredential uc = await _auth.signInWithCredential(credential);
      final uid = uc.user!.uid;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      _setLoading(false);
      if (doc.exists) {
        _currentUser = UserModel.fromSnapshot(doc);
        notifyListeners();
        successCallback('existing_user');
      } else {
        successCallback('new_user'); 
      }
    } catch (e) {
      _setLoading(false);
      errorCallback('Lỗi đăng nhập: ${e.toString()}');
    }
  }
  Future<String> saveNewUserInfo(String name, String gender, String email) async {
    _setLoading(true);
    try {
      User? fbUser = _auth.currentUser; // Lấy user từ hệ thống SMS
      if (fbUser == null) throw Exception("Chưa xác thực số điện thoại");

      final uid = fbUser.uid; // Lấy đúng UID duy nhất
      final phone = fbUser.phoneNumber ?? _pendingPhone ?? '';

      UserModel newUser = UserModel(
        id: uid, // Gán UID làm id
        displayName: name.trim(),
        email: email.trim(),
        phone: phone,
        gender: gender,
        role: 'user',
        createdAt: DateTime.now(),
      );

      // LƯU VÀO FIRESTORE (Dùng `doc(uid)` thay vì `doc(phone)`)
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      _currentUser = newUser;
      
      _setLoading(false);
      notifyListeners();
      return 'success';
    } catch (e) {
      _setLoading(false);
      return 'Lỗi hệ thống: $e';
    }
  }

  // =======================================================
  // 4. LẤY DỮ LIỆU USER (Dùng để auto login)
  // =======================================================
  Future<void> _fetchAndSetUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromSnapshot(doc);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Lỗi fetch user: $e");
    }
  }

  // =======================================================
  // 5. CẬP NHẬT THÔNG TIN CÁ NHÂN (UPDATE PROFILE)
  // =======================================================
  Future<void> updateProfile({
    required String displayName, 
    required String email, 
    required String gender,
  }) async {
    try {
      final String? docId = _currentUser?.id; 

      if (docId == null) {
        debugPrint("Lỗi: Không tìm thấy ID người dùng để update");
        return;
      }

      // 1. Ghi đè dữ liệu mới lên Firebase Firestore
      await _firestore.collection('users').doc(docId).update({
        'displayName': displayName,
        'e-mail': email,   
        'gender': gender,
      });

      // 2. Cập nhật lại bản sao trong máy (Tránh việc phải tải lại app)
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          displayName: displayName,
          email: email,
          gender: gender,
        );
        notifyListeners(); // Kích hoạt lệnh vẽ lại giao diện ở ProfileScreen
      }
    } catch (e) {
      debugPrint("Lỗi update: $e");
      rethrow;
    }
  }

  // =======================================================
  // 6. ĐĂNG XUẤT
  // =======================================================
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}