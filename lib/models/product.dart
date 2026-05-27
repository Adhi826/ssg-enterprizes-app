import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String brand;
  final String category; // 'Water', 'Soft Drinks', 'Carton Stock', 'Wholesale Beverages'
  final String stockType; // 'Carton', 'Case', 'Single'
  final int quantity;
  final int minQuantity;
  final double buyingPrice;
  final double price; // Selling price
  final String supplier;
  final String barcode;
  final String imageUrl;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.stockType,
    required this.quantity,
    required this.minQuantity,
    required this.buyingPrice,
    required this.price,
    required this.supplier,
    required this.barcode,
    required this.imageUrl,
    required this.description,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  bool get isLowStock => quantity <= minQuantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'stockType': stockType,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'buyingPrice': buyingPrice,
      'price': price,
      'supplier': supplier,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? 'Water',
      stockType: map['stockType'] ?? 'Single',
      quantity: map['quantity']?.toInt() ?? 0,
      minQuantity: map['minQuantity']?.toInt() ?? 5,
      buyingPrice: map['buyingPrice']?.toDouble() ?? 0.0,
      price: map['price']?.toDouble() ?? 0.0,
      supplier: map['supplier'] ?? '',
      barcode: map['barcode'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) => Product.fromMap(json.decode(source));

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? stockType,
    int? quantity,
    int? minQuantity,
    double? buyingPrice,
    double? price,
    String? supplier,
    String? barcode,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      stockType: stockType ?? this.stockType,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      price: price ?? this.price,
      supplier: supplier ?? this.supplier,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
