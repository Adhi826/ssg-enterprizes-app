import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../providers/inventory_state.dart';
import '../widgets/glass_container.dart';
import '../services/firebase_service.dart';
import 'recycle_bin_screen.dart';
import 'stock_history_screen.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── PRODUCT FORM (Add / Edit) ────────────────────────────
  void _showProductForm(BuildContext context, [Product? product]) {
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name ?? '');
    final brandController = TextEditingController(text: product?.brand ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final minQtyController = TextEditingController(text: product?.minQuantity.toString() ?? '15');
    final buyingPriceController = TextEditingController(text: product?.buyingPrice.toString() ?? '');
    final sellingPriceController = TextEditingController(text: product?.price.toString() ?? '');
    final supplierController = TextEditingController(text: product?.supplier ?? '');
    final barcodeController = TextEditingController(text: product?.barcode ?? '');
    final descController = TextEditingController(text: product?.description ?? '');

    String category = product?.category ?? 'Water';
    String stockType = product?.stockType ?? 'Single';
    String imageUrl = product?.imageUrl ?? '';
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit : Icons.add_circle, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Edit Product' : 'Add New Product',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Upload
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 70);
                      if (file != null) {
                        setState(() => isUploadingImage = true);
                        try {
                          final url = await FirebaseService().uploadProductImage(File(file.path), file.name);
                          setState(() { imageUrl = url; isUploadingImage = false; });
                        } catch (e) {
                          setState(() { imageUrl = file.path; isUploadingImage = false; });
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: imageUrl.startsWith('http')
                                    ? NetworkImage(imageUrl) as ImageProvider
                                    : FileImage(File(imageUrl)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: isUploadingImage
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
                          : imageUrl.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.camera_alt_outlined, color: Colors.white30, size: 28),
                                    SizedBox(height: 4),
                                    Text('Tap to add photo', style: TextStyle(color: Colors.white30, fontSize: 11)),
                                  ],
                                )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _formField(nameController, 'Product Name', Icons.inventory_2_outlined),
                  _formField(brandController, 'Brand', Icons.branding_watermark),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecor('Category'),
                          items: ['Water', 'Soft Drinks', 'Carton Stock', 'Wholesale Beverages']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => category = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: stockType,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _inputDecor('Stock Type'),
                          items: ['Single', 'Case', 'Carton']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => stockType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _formField(quantityController, 'Qty', Icons.format_list_numbered, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _formField(minQtyController, 'Min Qty', Icons.warning_amber, isNumber: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _formField(buyingPriceController, 'Buy Price', Icons.money, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _formField(sellingPriceController, 'Sell Price', Icons.sell, isNumber: true)),
                    ],
                  ),
                  _formField(supplierController, 'Supplier', Icons.local_shipping),
                  _formField(barcodeController, 'Barcode', Icons.qr_code),
                  _formField(descController, 'Description', Icons.description),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final newProduct = Product(
                    id: product?.id ?? '',
                    name: nameController.text.trim(),
                    brand: brandController.text.trim(),
                    category: category,
                    stockType: stockType,
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    minQuantity: int.tryParse(minQtyController.text) ?? 15,
                    buyingPrice: double.tryParse(buyingPriceController.text) ?? 0,
                    price: double.tryParse(sellingPriceController.text) ?? 0,
                    supplier: supplierController.text.trim(),
                    barcode: barcodeController.text.trim(),
                    imageUrl: imageUrl,
                    description: descController.text.trim(),
                    createdAt: product?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (isEditing) {
                    ref.read(inventoryStateProvider.notifier).updateProduct(newProduct);
                  } else {
                    ref.read(inventoryStateProvider.notifier).addProduct(newProduct);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: _inputDecor(label, icon: icon),
      ),
    );
  }

  InputDecoration _inputDecor(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.white24) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  // ─── DELETE CONFIRMATION DIALOG ───────────────────────────
  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('Delete Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${product.name}"?',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can restore it later from the Recycle Bin.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Move to Recycle Bin'),
            onPressed: () {
              ref.read(inventoryStateProvider.notifier).moveToRecycleBin(product);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} moved to Recycle Bin'),
                  backgroundColor: Colors.redAccent,
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.white,
                    onPressed: () {
                      ref.read(inventoryStateProvider.notifier).restoreProduct(product);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryStateProvider);
    final notifier = ref.read(inventoryStateProvider.notifier);
    final filteredProducts = invState.filteredProducts;
    final dateFormat = DateFormat('dd MMM yy');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Product Inventory', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          actions: [
            // View toggle
            IconButton(
              icon: Icon(invState.isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white70),
              onPressed: () => notifier.toggleViewMode(),
              tooltip: invState.isGridView ? 'List View' : 'Grid View',
            ),
            // Recycle Bin
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                  if (invState.deletedProducts.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '${invState.deletedProducts.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinScreen())),
              tooltip: 'Recycle Bin',
            ),
            // History
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white70),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockHistoryScreen())),
              tooltip: 'Stock History',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showProductForm(context),
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            // ─── SEARCH BAR ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  onChanged: (val) => notifier.setSearchQuery(val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, brand, or barcode...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ─── FILTER CHIPS ───────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('All', invState.categoryFilter, (v) => notifier.setCategoryFilter(v)),
                  _filterChip('Water', invState.categoryFilter, (v) => notifier.setCategoryFilter(v)),
                  _filterChip('Soft Drinks', invState.categoryFilter, (v) => notifier.setCategoryFilter(v)),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 24, color: Colors.white12),
                  const SizedBox(width: 8),
                  _filterChip('All', invState.stockStatusFilter, (v) => notifier.setStockStatusFilter(v), label: 'All Stock'),
                  _filterChip('Low Stock', invState.stockStatusFilter, (v) => notifier.setStockStatusFilter(v), color: Colors.orangeAccent),
                  _filterChip('Out of Stock', invState.stockStatusFilter, (v) => notifier.setStockStatusFilter(v), color: Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ─── RESULTS COUNT ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredProducts.length} product${filteredProducts.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  Text(
                    'Total Stock: ${invState.products.fold<int>(0, (s, p) => s + p.quantity)}',
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ─── PRODUCT LIST / GRID ────────────────────────
            Expanded(
              child: invState.isLoading
                  ? _buildLoadingSkeleton()
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
                              const SizedBox(height: 12),
                              const Text('No products found', style: TextStyle(color: Colors.white38, fontSize: 14)),
                            ],
                          ),
                        )
                      : invState.isGridView
                          ? _buildGridView(filteredProducts, dateFormat)
                          : _buildListView(filteredProducts, dateFormat),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FILTER CHIP WIDGET ─────────────────────────────────────
  Widget _filterChip(String value, String currentFilter, Function(String) onTap, {String? label, Color? color}) {
    final isActive = value == currentFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? (color ?? Colors.cyanAccent).withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? (color ?? Colors.cyanAccent) : Colors.white12),
          ),
          child: Text(
            label ?? value,
            style: TextStyle(
              color: isActive ? (color ?? Colors.cyanAccent) : Colors.white54,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ─── LOADING SKELETON ──────────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 70, height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LIST VIEW ─────────────────────────────────────────────
  Widget _buildListView(List<Product> products, DateFormat dateFormat) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
          child: Dismissible(
            key: Key(product.id),
            background: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.transparent, Color(0xFFE53E3E)]),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              _showDeleteDialog(product);
              return false;
            },
            child: _buildProductCard(product, dateFormat),
          ),
        );
      },
    );
  }

  // ─── GRID VIEW ─────────────────────────────────────────────
  Widget _buildGridView(List<Product> products, DateFormat dateFormat) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildGridCard(product, dateFormat);
      },
    );
  }

  // ─── LIST PRODUCT CARD ─────────────────────────────────────
  Widget _buildProductCard(Product product, DateFormat dateFormat) {
    Color stockColor = product.quantity == 0
        ? Colors.redAccent
        : product.isLowStock
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showProductForm(context, product),
        onLongPress: () => _showDeleteDialog(product),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 72,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: product.imageUrl.startsWith('http')
                            ? NetworkImage(product.imageUrl) as ImageProvider
                            : FileImage(File(product.imageUrl)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl.isEmpty
                  ? Icon(
                      product.category == 'Water' ? Icons.water_drop : Icons.local_drink,
                      color: Colors.cyanAccent.withOpacity(0.3),
                      size: 28,
                    )
                  : null,
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${product.brand} • ${product.category}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.quantity == 0 ? 'OUT' : '${product.quantity} ${product.stockType}',
                            style: TextStyle(color: stockColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white24, size: 20),
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') _showProductForm(context, product);
                if (val == 'delete') _showDeleteDialog(product);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: Colors.cyanAccent), SizedBox(width: 8), Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13))])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.redAccent), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.white, fontSize: 13))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── GRID PRODUCT CARD ─────────────────────────────────────
  Widget _buildGridCard(Product product, DateFormat dateFormat) {
    Color stockColor = product.quantity == 0
        ? Colors.redAccent
        : product.isLowStock
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return GestureDetector(
      onTap: () => _showProductForm(context, product),
      onLongPress: () => _showDeleteDialog(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: product.imageUrl.startsWith('http')
                            ? NetworkImage(product.imageUrl) as ImageProvider
                            : FileImage(File(product.imageUrl)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl.isEmpty
                  ? Center(
                      child: Icon(
                        product.category == 'Water' ? Icons.water_drop : Icons.local_drink,
                        color: Colors.cyanAccent.withOpacity(0.2),
                        size: 36,
                      ),
                    )
                  : null,
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(product.brand, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: stockColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            product.quantity == 0 ? 'OUT' : '${product.quantity}',
                            style: TextStyle(color: stockColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    if (product.updatedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(dateFormat.format(product.updatedAt!), style: const TextStyle(color: Colors.white24, fontSize: 9)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
