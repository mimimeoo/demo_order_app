class PromoModel {
  final String id;
  final String title;
  final String description;
  final String expiryDate;
  final double discountValue;
  final bool isUsed;

  PromoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.expiryDate,
    required this.discountValue,
    this.isUsed = false,
  });

  // ĐÂY LÀ ĐOẠN BẠN ĐANG THIẾU
  factory PromoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PromoModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      // Chuyển đổi an toàn sang double dù trên Firestore là int hay double
      discountValue: (map['discountValue'] ?? 0).toDouble(),
      isUsed: map['isUsed'] ?? false,
    );
  }
}