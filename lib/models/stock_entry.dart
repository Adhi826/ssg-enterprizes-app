import 'dart:convert';

class StockEntry {
  final String id;
  final String type; // 'Incoming' or 'Outgoing'
  final DateTime dateTime;
  final String productId;
  final String productName;
  final String brandName;
  final int quantity;
  final String personName;
  final String notes;

  StockEntry({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.quantity,
    required this.personName,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'dateTime': dateTime.toIso8601String(),
      'productId': productId,
      'productName': productName,
      'brandName': brandName,
      'quantity': quantity,
      'personName': personName,
      'notes': notes,
    };
  }

  factory StockEntry.fromMap(Map<String, dynamic> map) {
    return StockEntry(
      id: map['id'] ?? '',
      type: map['type'] ?? 'Incoming',
      dateTime: DateTime.parse(map['dateTime']),
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      brandName: map['brandName'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      personName: map['personName'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StockEntry.fromJson(String source) => StockEntry.fromMap(json.decode(source));
}
