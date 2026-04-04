class ProductModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final double rating;
  final bool isPopular;
  final bool showOnHome;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.isPopular,
    this.showOnHome = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toInt() ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
      isPopular: json['isPopular'] ?? false,
      showOnHome: json['showOnHome'] ?? true,
    );
  }

  
  String get formattedPrice {
    return "${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }
}