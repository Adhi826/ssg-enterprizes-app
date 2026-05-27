import 'dart:convert';

class PaymentRecord {
  final String id;
  final String dueId;
  final String invoiceNumber;
  final String customerName;
  final double paidAmount;
  final DateTime date;
  final String paymentMethod; // 'Cash', 'UPI'
  final String notes;

  PaymentRecord({
    required this.id,
    required this.dueId,
    required this.invoiceNumber,
    required this.customerName,
    required this.paidAmount,
    required this.date,
    required this.paymentMethod,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dueId': dueId,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'paidAmount': paidAmount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] ?? '',
      dueId: map['dueId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerName: map['customerName'] ?? '',
      paidAmount: map['paidAmount']?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentRecord.fromJson(String source) => PaymentRecord.fromMap(json.decode(source));
}
