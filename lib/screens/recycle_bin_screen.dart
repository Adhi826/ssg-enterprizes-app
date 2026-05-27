import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_state.dart';
import '../models/product.dart';
import '../widgets/glass_container.dart';

class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryStateProvider);
    final notifier = ref.read(inventoryStateProvider.notifier);
    final deletedProducts = invState.deletedProducts;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0F0F), Color(0xFF2D1B1B), Color(0xFF1E293B)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              const SizedBox(width: 10),
              const Text('Recycle Bin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              const SizedBox(width: 8),
              if (deletedProducts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('${deletedProducts.length}', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        body: deletedProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.recycling_rounded, size: 64, color: Colors.white.withOpacity(0.08)),
                    const SizedBox(height: 16),
                    const Text('Recycle Bin is Empty', style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    const Text('Deleted products will appear here', style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: deletedProducts.length,
                itemBuilder: (context, index) {
                  final product = deletedProducts[index];
                  return _buildDeletedProductCard(context, product, notifier, ref);
                },
              ),
      ),
    );
  }

  Widget _buildDeletedProductCard(BuildContext context, Product product, InventoryNotifier notifier, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    product.category == 'Water' ? Icons.water_drop : Icons.local_drink,
                    color: Colors.redAccent.withOpacity(0.5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14, decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.brand} • ${product.category} • Stock: ${product.quantity}',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent, width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      notifier.restoreProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} restored successfully!'),
                          backgroundColor: Colors.greenAccent.shade700,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text('Delete Forever', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Permanent Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: Text(
                            'This will permanently delete "${product.name}". This action cannot be undone.',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () {
                                notifier.permanentlyDeleteProduct(product.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Delete Forever'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
