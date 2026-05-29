import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/customer_due.dart';
import '../models/payment_record.dart';
import '../services/firebase_service.dart';
import 'auth_state.dart';

class BillingState {
  final List<Invoice> invoices;
  final List<InvoiceItem> draftItems;
  final String customerName;
  final String customerPhone;
  final double discountAmount;
  final double gstPercentage;
  final String paymentStatus;
  final String invoiceNotes;
  final String paymentType; // 'Full', 'Partial', 'Borrow'
  final double paidAmount;
  final DateTime? dueDate;
  final List<CustomerDue> customerDues;
  final List<PaymentRecord> paymentHistory;

  BillingState({
    required this.invoices,
    required this.draftItems,
    required this.customerName,
    required this.customerPhone,
    required this.discountAmount,
    required this.gstPercentage,
    required this.paymentStatus,
    required this.invoiceNotes,
    this.paymentType = 'Full',
    this.paidAmount = 0.0,
    this.dueDate,
    this.customerDues = const [],
    this.paymentHistory = const [],
  });

  double get subTotal => draftItems.fold(0.0, (sum, item) => sum + item.total);
  double get gstAmount => 0.0; // Removed GST
  double get grandTotal {
    double total = (subTotal - discountAmount) + gstAmount;
    return total < 0 ? 0.0 : total;
  }

  double get calculatedPaidAmount {
    if (paymentType == 'Full') {
      return grandTotal;
    } else if (paymentType == 'Borrow') {
      return 0.0;
    } else {
      return paidAmount;
    }
  }

  double get calculatedRemainingAmount {
    if (paymentType == 'Full') {
      return 0.0;
    } else if (paymentType == 'Borrow') {
      return grandTotal;
    } else {
      double rem = grandTotal - paidAmount;
      return rem < 0 ? 0.0 : rem;
    }
  }

  String get calculatedPaymentStatus {
    if (paymentType == 'Full') {
      return 'Paid';
    } else if (paymentType == 'Borrow') {
      return 'Pending';
    } else {
      return calculatedRemainingAmount > 0 ? 'Partial' : 'Paid';
    }
  }

  BillingState copyWith({
    List<Invoice>? invoices,
    List<InvoiceItem>? draftItems,
    String? customerName,
    String? customerPhone,
    double? discountAmount,
    double? gstPercentage,
    String? paymentStatus,
    String? invoiceNotes,
    String? paymentType,
    double? paidAmount,
    DateTime? dueDate,
    List<CustomerDue>? customerDues,
    List<PaymentRecord>? paymentHistory,
  }) {
    return BillingState(
      invoices: invoices ?? this.invoices,
      draftItems: draftItems ?? this.draftItems,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      discountAmount: discountAmount ?? this.discountAmount,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceNotes: invoiceNotes ?? this.invoiceNotes,
      paymentType: paymentType ?? this.paymentType,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      customerDues: customerDues ?? this.customerDues,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  final Ref ref;
  final AuthState authState;
  final FirebaseService _fbService = FirebaseService();
  StreamSubscription? _invoicesSubscription;
  StreamSubscription? _duesSubscription;
  StreamSubscription? _paymentsSubscription;

  BillingNotifier(this.ref, this.authState) : super(BillingState(
    invoices: [],
    draftItems: [],
    customerName: '',
    customerPhone: '',
    discountAmount: 0.0,
    gstPercentage: 18.0,
    paymentStatus: 'Paid',
    invoiceNotes: '',
    paymentType: 'Full',
    paidAmount: 0.0,
    customerDues: [],
    paymentHistory: [],
  )) {
    if (authState.isAuthenticated) {
      _initDataSync();
    } else {
      // Clear data or load samples for guest/default view if not authenticated
      state = BillingState(
        invoices: [],
        draftItems: [],
        customerName: '',
        customerPhone: '',
        discountAmount: 0.0,
        gstPercentage: 18.0,
        paymentStatus: 'Paid',
        invoiceNotes: '',
        paymentType: 'Full',
        paidAmount: 0.0,
        customerDues: [],
        paymentHistory: [],
      );
    }
  }

  void _initDataSync() {
    try {
      _invoicesSubscription = _fbService.getInvoicesStream().listen((fbInvoices) {
        state = state.copyWith(invoices: fbInvoices);
      }, onError: (err) {
        print("Firestore invoices listen error: $err");
      });

      _duesSubscription = _fbService.getCustomerDuesStream().listen((fbDues) {
        state = state.copyWith(customerDues: fbDues);
      }, onError: (err) {
        print("Firestore customer dues listen error: $err");
      });

      _paymentsSubscription = _fbService.getPaymentHistoryStream().listen((fbPayments) {
        state = state.copyWith(paymentHistory: fbPayments);
      }, onError: (err) {
        print("Firestore payment history listen error: $err");
      });
    } catch (e) {
      print("Firebase init failed: $e");
    }
  }

  void _loadSampleBills() {
    final now = DateTime.now();
    final billsList = [
      Invoice(
        id: 'inv_1',
        invoiceNumber: 'SSGE-2026-101',
        customerName: 'Krishna Kirana Store',
        customerPhone: '7036657769',
        items: [
          InvoiceItem(
            productId: 'prod_1',
            productName: 'Bisleri Mineral Water 1L',
            brandName: 'Bisleri',
            stockType: 'Single',
            quantity: 50,
            unitPrice: 20.0,
            total: 1000.0,
          ),
          InvoiceItem(
            productId: 'prod_4',
            productName: 'Sprite Carton (24 Cans)',
            brandName: 'Coca Cola',
            stockType: 'Carton',
            quantity: 2,
            unitPrice: 480.0,
            total: 960.0,
          )
        ],
        subTotal: 1960.0,
        gstPercentage: 18.0,
        gstAmount: 352.8,
        discountAmount: 100.0,
        grandTotal: 2212.8,
        paymentStatus: 'Paid',
        date: now.subtract(const Duration(days: 3)),
        notes: 'Rajampalli warehouse delivery',
      )
    ];

    state = state.copyWith(invoices: billsList);
  }

  void setCustomerDetails(String name, String phone) {
    state = state.copyWith(customerName: name, customerPhone: phone);
  }

  void updateDiscount(double discount) {
    state = state.copyWith(discountAmount: discount);
  }

  void updatePaymentStatus(String status) {
    state = state.copyWith(paymentStatus: status);
  }

  void updatePaymentType(String type) {
    state = state.copyWith(paymentType: type);
  }

  void updatePaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }

  void updateDueDate(DateTime? date) {
    state = state.copyWith(dueDate: date);
  }

  void setNotes(String notes) {
    state = state.copyWith(invoiceNotes: notes);
  }

  void addProductToInvoice(Product product, int quantity) {
    final draft = List<InvoiceItem>.from(state.draftItems);
    final index = draft.indexWhere((item) => item.productId == product.id);

    if (index != -1) {
      final existingItem = draft[index];
      int newQty = existingItem.quantity + quantity;
      draft[index] = InvoiceItem(
        productId: product.id,
        productName: product.name,
        brandName: product.brand,
        stockType: product.stockType,
        quantity: newQty,
        unitPrice: product.price,
        total: newQty * product.price,
      );
    } else {
      draft.add(InvoiceItem(
        productId: product.id,
        productName: product.name,
        brandName: product.brand,
        stockType: product.stockType,
        quantity: quantity,
        unitPrice: product.price,
        total: quantity * product.price,
      ));
    }
    state = state.copyWith(draftItems: draft);
  }

  void updateItemQuantity(String productId, int quantity) {
    List<InvoiceItem> draft = List.from(state.draftItems);
    final index = draft.indexWhere((item) => item.productId == productId);

    if (index != -1) {
      if (quantity <= 0) {
        draft.removeAt(index);
      } else {
        final item = draft[index];
        draft[index] = InvoiceItem(
          productId: item.productId,
          productName: item.productName,
          brandName: item.brandName,
          stockType: item.stockType,
          quantity: quantity,
          unitPrice: item.unitPrice,
          total: quantity * item.unitPrice,
        );
      }
      state = state.copyWith(draftItems: draft);
    }
  }

  void clearDraft() {
    state = state.copyWith(
      customerName: '',
      customerPhone: '',
      draftItems: [],
      discountAmount: 0.0,
      paymentStatus: 'Paid',
      invoiceNotes: '',
      paymentType: 'Full',
      paidAmount: 0.0,
      dueDate: null,
    );
  }

  Invoice saveInvoice() {
    final number = 'SSGE-2026-${state.invoices.length + 101}';
    final invoiceId = const Uuid().v4();
    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: number,
      customerName: state.customerName.isEmpty ? 'General Customer' : state.customerName,
      customerPhone: state.customerPhone,
      items: List.from(state.draftItems),
      subTotal: state.subTotal,
      gstPercentage: state.gstPercentage,
      gstAmount: state.gstAmount,
      discountAmount: state.discountAmount,
      grandTotal: state.grandTotal,
      paymentStatus: state.calculatedPaymentStatus,
      date: DateTime.now(),
      notes: state.invoiceNotes,
      paymentType: state.paymentType,
      paidAmount: state.calculatedPaidAmount,
      remainingAmount: state.calculatedRemainingAmount,
      dueDate: state.dueDate ?? DateTime.now().add(const Duration(days: 15)),
    );

    // Create CustomerDue record if there is a remaining balance
    CustomerDue? customerDue;
    if (invoice.remainingAmount > 0) {
      customerDue = CustomerDue(
        id: 'due_${invoice.id.replaceAll('fb_', '').replaceAll('i_', '')}',
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        invoiceId: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        totalAmount: invoice.grandTotal,
        paidAmount: invoice.paidAmount,
        remainingAmount: invoice.remainingAmount,
        date: invoice.date,
        dueDate: invoice.dueDate ?? invoice.date.add(const Duration(days: 15)),
        status: invoice.paymentStatus,
      );
    }

    // Save to Firestore in background
    _fbService.saveInvoice(invoice, {}, due: customerDue).catchError((err) {
      print("Firestore invoice write error: $err");
    });

    state = state.copyWith(
      invoices: [invoice, ...state.invoices],
    );
    clearDraft();
    return invoice;
  }

  Future<void> deleteInvoice(Invoice invoice) async {
    try {
      await _fbService.deleteInvoice(invoice.id);
    } catch (e) {
      print("Firestore invoice delete error: $e");
    }
    
    final updated = state.invoices.where((inv) => inv.id != invoice.id).toList();
    state = state.copyWith(invoices: updated);
  }

  Future<void> recordRepayment({
    required PaymentRecord payment,
    required CustomerDue due,
    required Invoice invoice,
  }) async {
    try {
      await _fbService.recordRepayment(payment: payment, due: due, invoice: invoice);
    } catch (e) {
      print("Firestore record repayment error: $e");
    }
  }

  @override
  void dispose() {
    _invoicesSubscription?.cancel();
    _duesSubscription?.cancel();
    _paymentsSubscription?.cancel();
    super.dispose();
  }
}

final billingStateProvider = StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  final authState = ref.watch(authStateProvider);
  return BillingNotifier(ref, authState);
});
