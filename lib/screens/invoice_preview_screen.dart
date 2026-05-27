import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';
import '../widgets/glass_container.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final Invoice invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Invoice Preview', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Invoice Header Branding Card
              GlassContainer(
                padding: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SRI SIVA GAYATHRI',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                                letterSpacing: 1,
                              ),
                            ),
                            const Text(
                              'ENTERPRIZES',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.cyanAccent,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Water & Soft Drinks Distributors',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.cyanAccent, size: 13),
                                const SizedBox(width: 4),
                                const Text('Rajampalli', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.cyanAccent, size: 13),
                                const SizedBox(width: 4),
                                const Text('7036657769 / 9000990191', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D2FF), Color(0xFF0072FF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'INVOICE',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 25),

                    // Invoice Metadata
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BILL TO:', style: TextStyle(color: Colors.white50, fontSize: 11)),
                            Text(
                              invoice.customerName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (invoice.customerPhone.isNotEmpty)
                              Text(invoice.customerPhone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              dateFormat.format(invoice.date),
                              style: const TextStyle(color: Colors.white50, fontSize: 10),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: invoice.paymentStatus.toLowerCase() == 'paid'
                                    ? Colors.green.withOpacity(0.2)
                                    : (invoice.paymentStatus.toLowerCase() == 'partial'
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: invoice.paymentStatus.toLowerCase() == 'paid'
                                      ? Colors.greenAccent
                                      : (invoice.paymentStatus.toLowerCase() == 'partial'
                                          ? Colors.orangeAccent
                                          : Colors.redAccent),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                invoice.paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: invoice.paymentStatus.toLowerCase() == 'paid'
                                      ? Colors.greenAccent
                                      : (invoice.paymentStatus.toLowerCase() == 'partial'
                                          ? Colors.orangeAccent
                                          : Colors.redAccent),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 25),

                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Item Description', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(child: Text('Qty', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                          Expanded(child: Text('Rate', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                          Expanded(child: Text('Amount', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Line items
                    ...invoice.items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        decoration: BoxDecoration(
                          color: idx.isEven ? Colors.white.withOpacity(0.03) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text(item.brandName, style: const TextStyle(color: Colors.white50, fontSize: 10)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text('₹${item.unitPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              child: Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(color: Colors.white24, height: 20),

                    // Totals Summary
                    _buildTotalRow('Subtotal:', '₹${invoice.subTotal.toStringAsFixed(2)}', Colors.white70, Colors.white),
                    if (invoice.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildTotalRow('Discount:', '- ₹${invoice.discountAmount.toStringAsFixed(2)}', Colors.white70, Colors.greenAccent),
                    ],
                    const SizedBox(height: 6),
                    // GST row removed
                     const Divider(color: Colors.white24, height: 16),
                     _buildTotalRow(
                       'Grand Total:',
                       '₹${invoice.grandTotal.toStringAsFixed(2)}',
                       Colors.cyanAccent,
                       Colors.cyanAccent,
                       isBold: true,
                       fontSize: 16,
                     ),
                     if (invoice.paymentType != 'Full') ...[
                       const Divider(color: Colors.white24, height: 16),
                       _buildTotalRow(
                         'Paid Amount:',
                         '₹${invoice.paidAmount.toStringAsFixed(2)}',
                         Colors.greenAccent,
                         Colors.greenAccent,
                       ),
                       const SizedBox(height: 6),
                       _buildTotalRow(
                         'Remaining Balance:',
                         '₹${invoice.remainingAmount.toStringAsFixed(2)}',
                         Colors.redAccent,
                         Colors.redAccent,
                         isBold: true,
                       ),
                     ],

                    // Notes section
                    if (invoice.notes.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 6),
                      Text(
                        'Notes: ${invoice.notes}',
                        style: const TextStyle(color: Colors.white50, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Footer branding
              GlassContainer(
                padding: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_outlined, color: Colors.cyanAccent, size: 14),
                    const SizedBox(width: 8),
                    const Text(
                      'Sri Siva Gayathri Enterprizes, Rajampalli',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.print_rounded,
                      label: 'Print Invoice',
                      color: Colors.blueAccent,
                      onTap: () => PdfService.printInvoice(invoice),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share_rounded,
                      label: 'Share PDF',
                      color: Colors.green,
                      onTap: () => PdfService.shareInvoicePdf(invoice),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Delete Invoice Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('⚠️ Delete Invoice?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to permanently delete Invoice "${invoice.invoiceNumber}"?\nStock quantities will be restored to inventory.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // Close dialog
                              
                              // 1. Restore stock
                              final invNotifier = ref.read(inventoryStateProvider.notifier);
                              for (var item in invoice.items) {
                                await invNotifier.addStockEntry(
                                  productId: item.productId,
                                  type: 'Incoming', // Restore stock
                                  quantity: item.quantity,
                                  personName: invoice.customerName,
                                  notes: 'Invoice deleted - Restored stock: ${invoice.invoiceNumber}',
                                );
                              }
                              
                              // 2. Delete invoice
                              await ref.read(billingStateProvider.notifier).deleteInvoice(invoice);
                              
                              // 3. Go back and show success toast
                              if (context.mounted) {
                                Navigator.of(context).pop(); // Pop preview screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Invoice ${invoice.invoiceNumber} deleted and stock restored successfully.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('DELETE INVOICE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),

              // Back button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyan,
                    side: const BorderSide(color: Colors.cyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('BACK TO BILLING', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, Color labelColor, Color valueColor, {bool isBold = false, double fontSize = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: fontSize)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
