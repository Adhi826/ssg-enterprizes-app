import 'dart:convert';

class CustomerDue {
  final String id;
  final String customerName;
  final String customerPhone;
  final String invoiceId;
  final String invoiceNumber;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime date;
  final DateTime dueDate;
  final String status; // 'Pending', 'Partial', 'Paid'

  CustomerDue({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.date,
    required this.dueDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
    };
  }

  factory CustomerDue.fromMap(Map<String, dynamic> map) {
    return CustomerDue(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      invoiceId: map['invoiceId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      paidAmount: map['paidAmount']?.toDouble() ?? 0.0,
      remainingAmount: map['remainingAmount']?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now().add(const Duration(days: 15)),
      status: map['status'] ?? 'Pending',
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomerDue.fromJson(String source) => CustomerDue.fromMap(json.decode(source));
}
