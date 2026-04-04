import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String role;
  final DateTime? createdAt;
  final String gender;
  final String dateOfBirth;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.createdAt,
    this.gender = '',
    this.dateOfBirth = '',
  });

  // CẬP NHẬT: Thêm gender vào copyWith để không bị mất dữ liệu khi update
  UserModel copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? role,
    String? gender, 
    String? dateOfBirth,
    // Thêm dòng này
  }) {
    return UserModel(
      id: this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gender: gender ?? this.gender, // Thêm dòng này
      createdAt: this.createdAt,
      dateOfBirth: this.dateOfBirth,
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return UserModel(
      id: snap.id, // Chính là cái +84852963741 trong ảnh
      displayName: data['displayName'] ?? '',
      // SỬA: Đọc đúng key 'e-mail' (có gạch ngang) từ ảnh Firebase của bạn
      email: data['e-mail'] ?? data['email'] ?? '',
      // SỬA: Đọc đúng key 'phoneNumber' từ ảnh Firebase của bạn
      phone: data['phoneNumber'] ?? snap.id,
      role: data['role'] ?? 'user',
      gender: data['gender'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'e-mail': email, // PHẢI dùng 'e-mail' để ghi đè đúng ô cũ
      'phoneNumber': phone, // PHẢI dùng 'phoneNumber' để không tạo cột mới
      'gender': gender,
      'role': role,
      'isProfileComplete': true,
    };
  }
}
