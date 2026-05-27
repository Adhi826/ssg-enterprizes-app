import 'dart:convert';

class InvoiceItem {
  final String productId;
  final String productName;
  final String brandName;
  final String stockType;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.stockType,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'brandName': brandName,
      'stockType': stockType,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      brandName: map['brandName'] ?? '',
      stockType: map['stockType'] ?? 'Single',
      quantity: map['quantity']?.toInt() ?? 0,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final List<InvoiceItem> items;
  final double subTotal;
  final double gstPercentage; // e.g. 18.0
  final double gstAmount;
  final double discountAmount;
  final double grandTotal;
  final String paymentStatus; // 'Paid', 'Pending', 'Unpaid'
  final DateTime date;
  final String notes;
  final String paymentType; // 'Full', 'Partial', 'Borrow'
  final double paidAmount;
  final double remainingAmount;
  final DateTime? dueDate;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subTotal,
    required this.gstPercentage,
    required this.gstAmount,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentStatus,
    required this.date,
    required this.notes,
    this.paymentType = 'Full',
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((x) => x.toMap()).toList(),
      'subTotal': subTotal,
      'gstPercentage': gstPercentage,
      'gstAmount': gstAmount,
      'discountAmount': discountAmount,
      'grandTotal': grandTotal,
      'paymentStatus': paymentStatus,
      'date': date.toIso8601String(),
      'notes': notes,
      'paymentType': paymentType,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      items: List<InvoiceItem>.from(map['items']?.map((x) => InvoiceItem.fromMap(x)) ?? const []),
      subTotal: map['subTotal']?.toDouble() ?? 0.0,
      gstPercentage: map['gstPercentage']?.toDouble() ?? 0.0,
      gstAmount: map['gstAmount']?.toDouble() ?? 0.0,
      discountAmount: map['discountAmount']?.toDouble() ?? 0.0,
      grandTotal: map['grandTotal']?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      date: DateTime.parse(map['date']),
      notes: map['notes'] ?? '',
      paymentType: map['paymentType'] ?? 'Full',
      paidAmount: map['paidAmount']?.toDouble() ?? (map['grandTotal']?.toDouble() ?? 0.0),
      remainingAmount: map['remainingAmount']?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Invoice.fromJson(String source) => Invoice.fromMap(json.decode(source));
}
