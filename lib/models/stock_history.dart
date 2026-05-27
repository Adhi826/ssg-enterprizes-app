import 'dart:convert';

class StockHistory {
  final String id;
  final String productId;
  final String productName;
  final String actionType; // 'Added', 'Edited', 'Incoming', 'Outgoing', 'Deleted', 'Restored'
  final DateTime timestamp;
  final String userName;
  final int previousStock;
  final int updatedStock;
  final String notes;

  StockHistory({
    required this.id,
    required this.productId,
    required this.productName,
    required this.actionType,
    required this.timestamp,
    required this.userName,
    required this.previousStock,
    required this.updatedStock,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'actionType': actionType,
      'timestamp': timestamp.toIso8601String(),
      'userName': userName,
      'previousStock': previousStock,
      'updatedStock': updatedStock,
      'notes': notes,
    };
  }

  factory StockHistory.fromMap(Map<String, dynamic> map) {
    return StockHistory(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      actionType: map['actionType'] ?? 'Unknown',
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
      userName: map['userName'] ?? 'Admin',
      previousStock: map['previousStock']?.toInt() ?? 0,
      updatedStock: map['updatedStock']?.toInt() ?? 0,
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StockHistory.fromJson(String source) => StockHistory.fromMap(json.decode(source));
}
