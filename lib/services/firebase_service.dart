import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product.dart';
import '../models/stock_entry.dart';
import '../models/invoice.dart';
import '../models/stock_history.dart';
import '../models/customer_due.dart';
import '../models/payment_record.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Helper method to scope business collections under the authenticated user's UID
  CollectionReference<Map<String, dynamic>> _userCollection(String collectionName) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("User must be authenticated to access Firestore.");
    }
    return _db.collection('users').doc(uid).collection(collectionName);
  }

  // ─── AUTHENTICATION SERVICES ─────────────────────────────────
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── PRODUCT / INVENTORY SERVICES ───────────────────────────

  Stream<List<Product>> getProductsStream() {
    return _userCollection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Set document id into product model
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
    });
  }

  Future<void> saveProduct(Product product, {String userName = 'Admin', bool isEdit = false}) async {
    final batch = _db.batch();
    final col = _userCollection('products');
    final docRef = col.doc(product.id.isEmpty ? null : product.id);
    final productMap = product.toMap();
    if (product.id.isEmpty) {
      productMap['id'] = docRef.id;
    }
    productMap['updatedAt'] = DateTime.now().toIso8601String();
    if (product.id.isEmpty) {
      productMap['createdAt'] = DateTime.now().toIso8601String();
    }
    batch.set(docRef, productMap, SetOptions(merge: true));

    // Also record history
    final histRef = _userCollection('stock_history').doc();
    final hist = StockHistory(
      id: histRef.id,
      productId: productMap['id'],
      productName: product.name,
      actionType: isEdit ? 'Edited' : 'Added',
      timestamp: DateTime.now(),
      userName: userName,
      previousStock: isEdit ? product.quantity : 0,
      updatedStock: product.quantity,
    );
    batch.set(histRef, hist.toMap());

    await batch.commit();
  }

  Future<void> moveToRecycleBin(Product product, {String userName = 'Admin'}) async {
    final batch = _db.batch();
    
    // Move to deleted_products collection
    final delRef = _userCollection('deleted_products').doc(product.id);
    final prodMap = product.copyWith(isDeleted: true).toMap();
    prodMap['deletedAt'] = DateTime.now().toIso8601String();
    batch.set(delRef, prodMap);
    
    // Remove from active products
    final prodRef = _userCollection('products').doc(product.id);
    batch.delete(prodRef);

    // Record history
    final histRef = _userCollection('stock_history').doc();
    final hist = StockHistory(
      id: histRef.id,
      productId: product.id,
      productName: product.name,
      actionType: 'Deleted',
      timestamp: DateTime.now(),
      userName: userName,
      previousStock: product.quantity,
      updatedStock: 0,
    );
    batch.set(histRef, hist.toMap());

    await batch.commit();
  }

  Stream<List<Product>> getDeletedProductsStream() {
    return _userCollection('deleted_products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    });
  }

  Future<void> restoreProduct(Product product, {String userName = 'Admin'}) async {
    final batch = _db.batch();
    
    // Add back to active products
    final prodRef = _userCollection('products').doc(product.id);
    batch.set(prodRef, product.copyWith(isDeleted: false).toMap());
    
    // Remove from deleted products
    final delRef = _userCollection('deleted_products').doc(product.id);
    batch.delete(delRef);

    // Record history
    final histRef = _userCollection('stock_history').doc();
    final hist = StockHistory(
      id: histRef.id,
      productId: product.id,
      productName: product.name,
      actionType: 'Restored',
      timestamp: DateTime.now(),
      userName: userName,
      previousStock: 0,
      updatedStock: product.quantity,
    );
    batch.set(histRef, hist.toMap());

    await batch.commit();
  }

  Future<void> permanentlyDeleteProduct(String id) async {
    await _userCollection('deleted_products').doc(id).delete();
  }

  // ─── STOCK ENTRY MOVEMENT SERVICES ─────────────────────────

  Stream<List<StockEntry>> getStockEntriesStream() {
    return _userCollection('stock_logs')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return StockEntry.fromMap(data);
      }).toList();
    });
  }

  Future<void> addBulkStockEntries(List<StockEntry> entries, Map<String, Product> currentProductsMap, {String userName = 'Admin'}) async {
    final batch = _db.batch();
    
    for (var entry in entries) {
      final logRef = _userCollection('stock_logs').doc();
      final entryMap = entry.toMap();
      entryMap['id'] = logRef.id;
      batch.set(logRef, entryMap);
      
      final product = currentProductsMap[entry.productId];
      if (product != null) {
        final prodRef = _userCollection('products').doc(entry.productId);
        int newQty = product.quantity + (entry.type == 'Incoming' ? entry.quantity : -entry.quantity);
        batch.update(prodRef, {'quantity': newQty});

        // Record history
        final histRef = _userCollection('stock_history').doc();
        final hist = StockHistory(
          id: histRef.id,
          productId: product.id,
          productName: product.name,
          actionType: entry.type == 'Incoming' ? 'Stock In' : 'Stock Out',
          timestamp: DateTime.now(),
          userName: userName,
          previousStock: product.quantity,
          updatedStock: newQty,
          notes: entry.notes,
        );
        batch.set(histRef, hist.toMap());
      }
    }
    
    await batch.commit();
  }

  Stream<List<StockHistory>> getStockHistoryStream() {
    return _userCollection('stock_history')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StockHistory.fromMap(doc.data())).toList();
    });
  }

  // ─── BILLING / INVOICE SERVICES ────────────────────────────

  Stream<List<Invoice>> getInvoicesStream() {
    return _userCollection('invoices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Invoice.fromMap(data);
      }).toList();
    });
  }

  Future<void> saveInvoice(Invoice invoice, Map<String, int> updatedProductQuantities, {CustomerDue? due}) async {
    final batch = _db.batch();
    
    final invRef = _userCollection('invoices').doc(invoice.id.isEmpty ? null : invoice.id);
    final invoiceMap = invoice.toMap();
    if (invoice.id.isEmpty) {
      invoiceMap['id'] = invRef.id;
    }
    
    batch.set(invRef, invoiceMap);
    
    // Deduct stock for each item in the invoice
    updatedProductQuantities.forEach((prodId, newQty) {
      final prodRef = _userCollection('products').doc(prodId);
      batch.update(prodRef, {'quantity': newQty});
    });

    if (due != null) {
      final dueRef = _userCollection('customer_dues').doc(due.id.isEmpty ? null : due.id);
      final dueMap = due.toMap();
      if (due.id.isEmpty) {
        dueMap['id'] = dueRef.id;
      }
      batch.set(dueRef, dueMap);
    }
    
    await batch.commit();
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _userCollection('invoices').doc(invoiceId).delete();
  }

  // ─── CUSTOMER DUE / REPAYMENT SERVICES ─────────────────────────

  Stream<List<CustomerDue>> getCustomerDuesStream() {
    return _userCollection('customer_dues').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomerDue.fromMap(data);
      }).toList();
    });
  }

  Stream<List<PaymentRecord>> getPaymentHistoryStream() {
    return _userCollection('payment_history')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PaymentRecord.fromMap(data);
      }).toList();
    });
  }

  Future<void> saveCustomerDue(CustomerDue due) async {
    await _userCollection('customer_dues').doc(due.id).set(due.toMap(), SetOptions(merge: true));
  }

  Future<void> recordRepayment({
    required PaymentRecord payment,
    required CustomerDue due,
    required Invoice invoice,
  }) async {
    final batch = _db.batch();
    
    // Add payment history record
    final payRef = _userCollection('payment_history').doc(payment.id.isEmpty ? null : payment.id);
    final payMap = payment.toMap();
    if (payment.id.isEmpty) {
      payMap['id'] = payRef.id;
    }
    batch.set(payRef, payMap);

    // Update customer due record
    final dueRef = _userCollection('customer_dues').doc(due.id);
    batch.set(dueRef, due.toMap(), SetOptions(merge: true));

    // Update invoice record
    final invRef = _userCollection('invoices').doc(invoice.id);
    batch.set(invRef, invoice.toMap(), SetOptions(merge: true));

    await batch.commit();
  }

  // ─── STORAGE SERVICES (PRODUCT IMAGE UPLOAD) ───────────────

  Future<String> uploadProductImage(File imageFile, String fileName) async {
    final ref = _storage.ref().child('product_images').child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  // ─── USER & SETTINGS SERVICES ──────────────────────────────

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  Future<void> saveSettings(String uid, Map<String, dynamic> settings) async {
    await _db.collection('settings').doc(uid).set(settings, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSettings(String uid) async {
    return await _db.collection('settings').doc(uid).get();
  }
}
