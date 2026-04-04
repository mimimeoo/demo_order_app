class AddressModel {
  final String id;
  final String label; 
  final String fullAddress;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      label: map['label'] ?? '',
      fullAddress: map['fullAddress'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}