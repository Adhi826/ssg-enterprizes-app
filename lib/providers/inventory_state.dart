import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/stock_entry.dart';
import '../models/stock_history.dart';
import '../services/firebase_service.dart';
import 'auth_state.dart';

class InventoryState {
  final List<Product> products;
  final List<StockEntry> stockEntries;
  final List<Product> deletedProducts;
  final List<StockHistory> stockHistory;
  final bool isLoading;

  // Filter & Search state
  final String searchQuery;
  final String categoryFilter; // 'All', 'Water', 'Soft Drinks'
  final String stockStatusFilter; // 'All', 'Low Stock', 'Out of Stock', 'In Stock'
  final String brandFilter; // 'All' or specific brand
  final bool isGridView;

  InventoryState({
    required this.products,
    required this.stockEntries,
    required this.deletedProducts,
    required this.stockHistory,
    required this.isLoading,
    this.searchQuery = '',
    this.categoryFilter = 'All',
    this.stockStatusFilter = 'All',
    this.brandFilter = 'All',
    this.isGridView = false,
  });

  // Filtered products based on current search/filter state
  List<Product> get filteredProducts {
    List<Product> result = List.from(products);

    // Search filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.barcode.toLowerCase().contains(q)
      ).toList();
    }

    // Category filter
    if (categoryFilter != 'All') {
      result = result.where((p) => p.category == categoryFilter).toList();
    }

    // Brand filter
    if (brandFilter != 'All') {
      result = result.where((p) => p.brand == brandFilter).toList();
    }

    // Stock status filter
    if (stockStatusFilter == 'Low Stock') {
      result = result.where((p) => p.isLowStock && p.quantity > 0).toList();
    } else if (stockStatusFilter == 'Out of Stock') {
      result = result.where((p) => p.quantity == 0).toList();
    } else if (stockStatusFilter == 'In Stock') {
      result = result.where((p) => p.quantity > 0).toList();
    }

    return result;
  }

  // Get unique brand names for filter chips
  List<String> get availableBrands {
    final brands = products.map((p) => p.brand).toSet().toList();
    brands.sort();
    return ['All', ...brands];
  }

  InventoryState copyWith({
    List<Product>? products,
    List<StockEntry>? stockEntries,
    List<Product>? deletedProducts,
    List<StockHistory>? stockHistory,
    bool? isLoading,
    String? searchQuery,
    String? categoryFilter,
    String? stockStatusFilter,
    String? brandFilter,
    bool? isGridView,
  }) {
    return InventoryState(
      products: products ?? this.products,
      stockEntries: stockEntries ?? this.stockEntries,
      deletedProducts: deletedProducts ?? this.deletedProducts,
      stockHistory: stockHistory ?? this.stockHistory,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      stockStatusFilter: stockStatusFilter ?? this.stockStatusFilter,
      brandFilter: brandFilter ?? this.brandFilter,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  final Ref ref;
  final AuthState authState;
  final FirebaseService _fbService = FirebaseService();
  StreamSubscription? _productsSubscription;
  StreamSubscription? _stockSubscription;
  StreamSubscription? _deletedSubscription;
  StreamSubscription? _historySubscription;

  InventoryNotifier(this.ref, this.authState) : super(InventoryState(
    products: [],
    stockEntries: [],
    deletedProducts: [],
    stockHistory: [],
    isLoading: false,
  )) {
    if (authState.isAuthenticated) {
      _initDataSync();
    } else {
      // Clear data or load samples for guest/default view if not authenticated
      state = InventoryState(
        products: [],
        stockEntries: [],
        deletedProducts: [],
        stockHistory: [],
        isLoading: false,
      );
    }
  }

  void _initDataSync() {
    state = state.copyWith(isLoading: true);

    try {
      _productsSubscription = _fbService.getProductsStream().listen((fbProducts) {
        state = state.copyWith(products: fbProducts, isLoading: false);
      }, onError: (err) {
        print("Firestore products listen error: $err");
        state = state.copyWith(isLoading: false);
      });

      _stockSubscription = _fbService.getStockEntriesStream().listen((fbLogs) {
        state = state.copyWith(stockEntries: fbLogs);
      }, onError: (err) {
        print("Firestore stock logs listen error: $err");
      });

      _deletedSubscription = _fbService.getDeletedProductsStream().listen((fbDeleted) {
        state = state.copyWith(deletedProducts: fbDeleted);
      }, onError: (err) {
        print("Firestore deleted products listen error: $err");
      });

      _historySubscription = _fbService.getStockHistoryStream().listen((fbHistory) {
        state = state.copyWith(stockHistory: fbHistory);
      }, onError: (err) {
        print("Firestore stock history listen error: $err");
      });
    } catch (e) {
      print("Firebase init failed: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void _loadSampleData() {
    state = state.copyWith(isLoading: true);

    final now = DateTime.now();
    final products = [
      Product(
        id: 'prod_1',
        name: 'Bisleri Mineral Water 1L',
        brand: 'Bisleri',
        category: 'Water',
        stockType: 'Single',
        quantity: 120,
        minQuantity: 20,
        buyingPrice: 15.0,
        price: 20.0,
        supplier: 'Bisleri Distributors Ltd',
        barcode: '8906001300015',
        imageUrl: '',
        description: 'Standard packaged mineral water bottle.',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      Product(
        id: 'prod_2',
        name: 'Kinley Water Case (12x1L)',
        brand: 'Kinley',
        category: 'Water',
        stockType: 'Case',
        quantity: 15,
        minQuantity: 5,
        buyingPrice: 180.0,
        price: 240.0,
        supplier: 'Coca Cola Beverages',
        barcode: '8901764032128',
        imageUrl: '',
        description: 'Kinley mineral water bottles case package.',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
      Product(
        id: 'prod_3',
        name: 'Thums Up Can 250ml',
        brand: 'Coca Cola',
        category: 'Soft Drinks',
        stockType: 'Single',
        quantity: 8,
        minQuantity: 15,
        buyingPrice: 30.0,
        price: 40.0,
        supplier: 'Sri Balaji Agencies',
        barcode: '8901764022204',
        imageUrl: '',
        description: 'Refreshing strong carbonated cola can.',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
      ),
      Product(
        id: 'prod_4',
        name: 'Sprite Carton (24 Cans)',
        brand: 'Coca Cola',
        category: 'Soft Drinks',
        stockType: 'Carton',
        quantity: 25,
        minQuantity: 8,
        buyingPrice: 380.0,
        price: 480.0,
        supplier: 'Sri Balaji Agencies',
        barcode: '8901764012229',
        imageUrl: '',
        description: 'Lemon-lime carbonated soft drink carton packaging.',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
    ];

    final stockEntries = [
      StockEntry(
        id: 'stk_1',
        type: 'Incoming',
        dateTime: now.subtract(const Duration(hours: 4)),
        productId: 'prod_1',
        productName: 'Bisleri Mineral Water 1L',
        brandName: 'Bisleri',
        quantity: 50,
        personName: 'Ramesh Kumar',
        notes: 'Refill batch',
      ),
      StockEntry(
        id: 'stk_2',
        type: 'Outgoing',
        dateTime: now.subtract(const Duration(hours: 2)),
        productId: 'prod_3',
        productName: 'Thums Up Can 250ml',
        brandName: 'Coca Cola',
        quantity: 12,
        personName: 'Suresh Kumar',
        notes: 'Grocery dispatch',
      ),
    ];

    state = InventoryState(
      products: products,
      stockEntries: stockEntries,
      deletedProducts: [],
      stockHistory: [],
      isLoading: false,
    );
  }

  // ─── FILTER & SEARCH ──────────────────────────────────────

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(categoryFilter: category);
  }

  void setStockStatusFilter(String status) {
    state = state.copyWith(stockStatusFilter: status);
  }

  void setBrandFilter(String brand) {
    state = state.copyWith(brandFilter: brand);
  }

  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  // ─── PRODUCT CRUD ─────────────────────────────────────────

  Future<void> addProduct(Product product) async {
    try {
      await _fbService.saveProduct(product, isEdit: false);
    } catch (e) {
      print("Firestore add error: $e");
      state = state.copyWith(products: [...state.products, product]);
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _fbService.saveProduct(product, isEdit: true);
    } catch (e) {
      print("Firestore update error: $e");
      state = state.copyWith(
        products: state.products.map((p) => p.id == product.id ? product : p).toList(),
      );
    }
  }

  // ─── RECYCLE BIN ──────────────────────────────────────────

  Future<void> moveToRecycleBin(Product product) async {
    try {
      await _fbService.moveToRecycleBin(product);
    } catch (e) {
      print("Firestore recycle error: $e");
      // Local fallback
      state = state.copyWith(
        products: state.products.where((p) => p.id != product.id).toList(),
        deletedProducts: [...state.deletedProducts, product.copyWith(isDeleted: true)],
      );
    }
  }

  Future<void> restoreProduct(Product product) async {
    try {
      await _fbService.restoreProduct(product);
    } catch (e) {
      print("Firestore restore error: $e");
      state = state.copyWith(
        deletedProducts: state.deletedProducts.where((p) => p.id != product.id).toList(),
        products: [...state.products, product.copyWith(isDeleted: false)],
      );
    }
  }

  Future<void> permanentlyDeleteProduct(String id) async {
    try {
      await _fbService.permanentlyDeleteProduct(id);
    } catch (e) {
      print("Firestore permanent delete error: $e");
      state = state.copyWith(
        deletedProducts: state.deletedProducts.where((p) => p.id != id).toList(),
      );
    }
  }

  // ─── STOCK ENTRIES (BULK SUPPORT) ─────────────────────────

  Future<void> addBulkStockEntries({
    required String type,
    required List<Map<String, dynamic>> items, // [{productId, quantity}]
    required String personName,
    required String notes,
  }) async {
    final entries = <StockEntry>[];
    final productsMap = <String, Product>{};

    for (var item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;
      final product = state.products.firstWhere((p) => p.id == productId);
      productsMap[productId] = product;

      entries.add(StockEntry(
        id: const Uuid().v4(),
        type: type,
        dateTime: DateTime.now(),
        productId: productId,
        productName: product.name,
        brandName: product.brand,
        quantity: quantity,
        personName: personName,
        notes: notes,
      ));
    }

    try {
      await _fbService.addBulkStockEntries(entries, productsMap);
    } catch (e) {
      print("Firestore bulk stock error: $e");
      // Local fallback
      List<Product> updatedProducts = List.from(state.products);
      for (var entry in entries) {
        final idx = updatedProducts.indexWhere((p) => p.id == entry.productId);
        if (idx != -1) {
          final p = updatedProducts[idx];
          int newQty = type == 'Incoming' ? p.quantity + entry.quantity : p.quantity - entry.quantity;
          if (newQty < 0) newQty = 0;
          updatedProducts[idx] = p.copyWith(quantity: newQty);
        }
      }
      state = state.copyWith(
        products: updatedProducts,
        stockEntries: [...entries, ...state.stockEntries],
      );
    }
  }

  // Legacy single stock entry (for backward compat)
  Future<void> addStockEntry({
    required String productId,
    required String type,
    required int quantity,
    required String personName,
    required String notes,
  }) async {
    await addBulkStockEntries(
      type: type,
      items: [{'productId': productId, 'quantity': quantity}],
      personName: personName,
      notes: notes,
    );
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _stockSubscription?.cancel();
    _deletedSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}

final inventoryStateProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  final authState = ref.watch(authStateProvider);
  return InventoryNotifier(ref, authState);
});
