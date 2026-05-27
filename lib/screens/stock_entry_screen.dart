import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_state.dart';
import '../models/product.dart';
import '../widgets/glass_container.dart';

class StockEntryScreen extends ConsumerStatefulWidget {
  const StockEntryScreen({super.key});

  @override
  ConsumerState<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends ConsumerState<StockEntryScreen> {
  String _selectedType = 'Incoming';
  final _personController = TextEditingController();
  final _notesController = TextEditingController();

  // Bulk items list: [{productId, quantity}]
  final List<Map<String, dynamic>> _bulkItems = [];

  @override
  void dispose() {
    _personController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addProductToBatch() {
    final invState = ref.read(inventoryStateProvider);
    String? selectedProductId;
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_box_rounded, color: Colors.cyanAccent, size: 22),
              SizedBox(width: 10),
              Text('Add Product to Batch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product search / select
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Select Product',
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: invState.products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (${p.quantity} in stock)', style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedProductId = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final qty = int.tryParse(qtyController.text);
                if (selectedProductId == null || qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a product and enter a valid quantity')),
                  );
                  return;
                }

                // Check if product already in batch
                final existing = _bulkItems.indexWhere((item) => item['productId'] == selectedProductId);
                if (existing != -1) {
                  this.setState(() {
                    _bulkItems[existing]['quantity'] = (_bulkItems[existing]['quantity'] as int) + qty;
                  });
                } else {
                  final product = invState.products.firstWhere((p) => p.id == selectedProductId);
                  this.setState(() {
                    _bulkItems.add({
                      'productId': selectedProductId!,
                      'productName': product.name,
                      'brand': product.brand,
                      'currentStock': product.quantity,
                      'quantity': qty,
                    });
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add to Batch'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitBulkTransaction() {
    if (_bulkItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product to the batch')),
      );
      return;
    }

    if (_personController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the recorder name')),
      );
      return;
    }

    // Validate outgoing stock
    if (_selectedType == 'Outgoing') {
      for (var item in _bulkItems) {
        final currentStock = item['currentStock'] as int;
        final qty = item['quantity'] as int;
        if (currentStock < qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Insufficient stock for ${item['productName']}. Only $currentStock available.')),
          );
          return;
        }
      }
    }

    final notifier = ref.read(inventoryStateProvider.notifier);
    notifier.addBulkStockEntries(
      type: _selectedType,
      items: _bulkItems.map((item) => {
        'productId': item['productId'] as String,
        'quantity': item['quantity'] as int,
      }).toList(),
      personName: _personController.text.trim(),
      notes: _notesController.text.trim(),
    );

    setState(() => _bulkItems.clear());
    _personController.clear();
    _notesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bulk ${_selectedType.toLowerCase()} transaction saved!'),
        backgroundColor: _selectedType == 'Incoming' ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryStateProvider);
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Stock Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── TYPE TOGGLE ──────────────────────────────
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaction Type', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedType = 'Incoming'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _selectedType == 'Incoming'
                                    ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00BFA5)])
                                    : null,
                                color: _selectedType != 'Incoming' ? Colors.white.withOpacity(0.05) : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward_rounded, color: _selectedType == 'Incoming' ? Colors.white : Colors.white38, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Incoming', style: TextStyle(
                                    color: _selectedType == 'Incoming' ? Colors.white : Colors.white38,
                                    fontWeight: FontWeight.bold, fontSize: 13,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedType = 'Outgoing'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _selectedType == 'Outgoing'
                                    ? const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFE53935)])
                                    : null,
                                color: _selectedType != 'Outgoing' ? Colors.white.withOpacity(0.05) : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward_rounded, color: _selectedType == 'Outgoing' ? Colors.white : Colors.white38, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Outgoing', style: TextStyle(
                                    color: _selectedType == 'Outgoing' ? Colors.white : Colors.white38,
                                    fontWeight: FontWeight.bold, fontSize: 13,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── BULK ITEMS LIST ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products in Batch (${_bulkItems.length})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.15),
                      foregroundColor: Colors.cyanAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _addProductToBatch,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_bulkItems.isEmpty)
                GlassContainer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 36, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 8),
                          const Text('No products in batch yet', style: TextStyle(color: Colors.white30, fontSize: 12)),
                          const Text('Tap "Add Product" to start', style: TextStyle(color: Colors.white20, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._bulkItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isIncoming = _selectedType == 'Incoming';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (isIncoming ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: (isIncoming ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isIncoming ? Colors.greenAccent : Colors.orangeAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['productName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${item['brand']} • Current: ${item['currentStock']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                        Text(
                          '${isIncoming ? '+' : '-'}${item['quantity']}',
                          style: TextStyle(
                            color: isIncoming ? Colors.greenAccent : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _bulkItems.removeAt(idx)),
                          child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // ─── RECORDER INFO ────────────────────────────
              GlassContainer(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _personController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Recorded By (Person Name)',
                        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.person_outline, size: 18, color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Notes / Reference',
                        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.note_outlined, size: 18, color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── SUBMIT BUTTON ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submitBulkTransaction,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedType == 'Incoming'
                            ? [const Color(0xFF00C853), const Color(0xFF00BFA5)]
                            : [const Color(0xFFFF6D00), const Color(0xFFE53935)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Save Bulk ${_selectedType} (${_bulkItems.length} items)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ─── RECENT STOCK LOG ─────────────────────────
              const Text('Recent Stock Movements', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invState.stockEntries.length,
                itemBuilder: (context, idx) {
                  final item = invState.stockEntries[idx];
                  final isIncoming = item.type == 'Incoming';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: GlassContainer(
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: (isIncoming ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isIncoming ? Colors.greenAccent : Colors.orangeAccent,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${item.brandName} • By: ${item.personName}', style: const TextStyle(color: Colors.white50, fontSize: 11)),
                                if (item.notes.isNotEmpty)
                                  Text(item.notes, style: const TextStyle(color: Colors.white30, fontSize: 10, fontStyle: FontStyle.italic)),
                                Text(dateFormat.format(item.dateTime), style: const TextStyle(color: Colors.cyanAccent, fontSize: 9)),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncoming ? '+' : '-'}${item.quantity}',
                            style: TextStyle(
                              color: isIncoming ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
