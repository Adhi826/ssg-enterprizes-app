import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_state.dart';
import '../providers/inventory_state.dart';
import '../services/excel_service.dart';
import '../widgets/glass_container.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingStateProvider);
    final invState = ref.watch(inventoryStateProvider);

    double totalRevenue = billingState.invoices.fold(0.0, (sum, item) => sum + item.grandTotal);
    double totalDiscounts = billingState.invoices.fold(0.0, (sum, item) => sum + item.discountAmount);
    // Removed GST

    // Profit estimation (selling - buying across invoiced items)
    double estimatedProfit = 0.0;
    for (var inv in billingState.invoices) {
      for (var item in inv.items) {
        final prodList = invState.products.where((p) => p.id == item.productId);
        if (prodList.isNotEmpty) {
          estimatedProfit += (item.unitPrice - prodList.first.buyingPrice) * item.quantity;
        }
      }
    }

    int waterSalesQty = 0;
    int sodaSalesQty = 0;
    for (var inv in billingState.invoices) {
      for (var item in inv.items) {
        final prod = invState.products.where((p) => p.id == item.productId);
        if (prod.isNotEmpty) {
          if (prod.first.category == 'Water') {
            waterSalesQty += item.quantity;
          } else {
            sodaSalesQty += item.quantity;
          }
        }
      }
    }

    final totalSalesQty = waterSalesQty + sodaSalesQty;

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
          title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Export panel
              const Text('Export Options', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              GlassContainer(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800),
                        icon: const Icon(Icons.table_chart, color: Colors.white, size: 20),
                        label: const Text('Export Sales Excel', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () async {
                          await ExcelService.exportSalesReport(billingState.invoices);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Excel Sales Report exported.')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                        label: const Text('Export Inventory', style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () async {
                          await ExcelService.exportInventoryReport(invState.products);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Inventory status exported.')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // KPI Stats
              const Text('Financial Highlights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _kpiCard('Total Revenue', 'Rs ${totalRevenue.toStringAsFixed(0)}', Colors.cyanAccent),
                  const SizedBox(width: 12),
                  _kpiCard('Est. Profit', 'Rs ${estimatedProfit.toStringAsFixed(0)}', Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _kpiCard('Discounts Given', 'Rs ${totalDiscounts.toStringAsFixed(0)}', Colors.orangeAccent),
                  const SizedBox(width: 12),
                  _kpiCard('Total Bills', '${billingState.invoices.length}', Colors.white),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _kpiCard('Bills Paid', '${billingState.invoices.where((i) => i.paymentStatus == 'Paid').length}', Colors.greenAccent),
                  const SizedBox(width: 12),
                  _kpiCard('Bills Pending', '${billingState.invoices.where((i) => i.paymentStatus != 'Paid').length}', Colors.redAccent),
                ],
              ),
              const SizedBox(height: 25),

              // Category distribution
              const Text('Sales Category Distribution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product quantity by category', style: TextStyle(color: Colors.white50, fontSize: 12)),
                    const SizedBox(height: 15),
                    
                    _progressRow(
                      'Water Bottles',
                      waterSalesQty,
                      totalSalesQty,
                      Colors.cyanAccent,
                    ),
                    const SizedBox(height: 12),
                    _progressRow(
                      'Soft Drinks',
                      sodaSalesQty,
                      totalSalesQty,
                      Colors.orangeAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // AI Predict restock
              const Text('AI Restock Predictions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto-calculated based on thresholds and demand:',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ...invState.products.where((p) => p.isLowStock).map((p) {
                      final suggested = p.minQuantity * 4 - p.quantity;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              p.quantity == 0 ? Icons.error : Icons.warning_amber_rounded,
                              size: 16,
                              color: p.quantity == 0 ? Colors.redAccent : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                                  children: [
                                    TextSpan(text: p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    TextSpan(text: ' (${p.brand}): '),
                                    TextSpan(
                                      text: p.quantity == 0 ? 'OUT OF STOCK. ' : 'Low (${p.quantity} left). ',
                                      style: TextStyle(color: p.quantity == 0 ? Colors.redAccent : Colors.orangeAccent),
                                    ),
                                    TextSpan(text: 'Suggest restock +$suggested ${p.stockType}s.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (invState.products.where((p) => p.isLowStock).isEmpty)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                          SizedBox(width: 10),
                          Text('All stock levels healthy — no restock needed.', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, Color valueColor) {
    return Expanded(
      child: GlassContainer(
        padding: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.5;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              color: color,
              backgroundColor: Colors.white10,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$count units', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
