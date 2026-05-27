import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_state.dart';
import '../providers/inventory_state.dart';
import '../models/product.dart';
import '../widgets/glass_container.dart';
import 'invoice_preview_screen.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  String _productSearchQuery = '';

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddProductDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final invState = ref.watch(inventoryStateProvider);
            final filtered = invState.products.where((p) {
              return p.name.toLowerCase().contains(_productSearchQuery.toLowerCase()) ||
                     p.brand.toLowerCase().contains(_productSearchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search product...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        _productSearchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final prod = filtered[idx];
                        return ListTile(
                          title: Text(prod.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${prod.brand} • Rs ${prod.price}', style: const TextStyle(color: Colors.white60)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                            onPressed: () {
                              if (prod.quantity <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Warning: Product is out of stock!')),
                                );
                              }
                              ref.read(billingStateProvider.notifier).addProductToInvoice(prod, 1);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${prod.name} added to cart.')),
                              );
                            },
                            child: const Text('Add', style: TextStyle(color: Colors.white)),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _generateBill() {
    final billingState = ref.read(billingStateProvider);
    final billingNotifier = ref.read(billingStateProvider.notifier);
    
    if (billingState.draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product to generate invoice')),
      );
      return;
    }

    billingNotifier.setCustomerDetails(_customerNameController.text.trim(), _customerPhoneController.text.trim());
    billingNotifier.updateDiscount(double.tryParse(_discountController.text) ?? 0.0);
    billingNotifier.setNotes(_notesController.text.trim());

    final savedInvoice = billingNotifier.saveInvoice();

    // Deduct quantities from Inventory
    final invNotifier = ref.read(inventoryStateProvider.notifier);
    for (var item in savedInvoice.items) {
      invNotifier.addStockEntry(
        productId: item.productId,
        type: 'Outgoing',
        quantity: item.quantity,
        personName: savedInvoice.customerName,
        notes: 'Invoice bill payment transaction: ${savedInvoice.invoiceNumber}',
      );
    }

    _customerNameController.clear();
    _customerPhoneController.clear();
    _discountController.text = '0';
    _notesController.clear();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(invoice: savedInvoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingStateProvider);
    final billingNotifier = ref.read(billingStateProvider.notifier);

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
          title: const Text('New Invoice Bill', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: () {
                billingNotifier.clearDraft();
                _customerNameController.clear();
                _customerPhoneController.clear();
                _discountController.text = '0';
                _notesController.clear();
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              GlassContainer(
                child: Column(
                  children: [
                    TextField(
                      controller: _customerNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.person, color: Colors.cyanAccent),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customerPhoneController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.phone, color: Colors.cyanAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Items added in Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                    onPressed: () => _showAddProductDialog(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                    label: const Text('Add Item', style: TextStyle(color: Colors.white, fontSize: 13)),
                  )
                ],
              ),
              const SizedBox(height: 10),

              if (billingState.draftItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Text(
                      'No items added yet. Tap Add Item button above.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: billingState.draftItems.length,
                  itemBuilder: (context, idx) {
                    final item = billingState.draftItems[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GlassContainer(
                        padding: 12,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text('Rs ${item.unitPrice} each', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => billingNotifier.updateItemQuantity(item.productId, item.quantity - 1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 20),
                                  onPressed: () => billingNotifier.updateItemQuantity(item.productId, item.quantity + 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Text('Rs ${item.total}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              const Text('Payment Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              GlassContainer(
                child: Column(
                  children: [
                    TextField(
                      controller: _discountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount (Rs)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (val) {
                        double d = double.tryParse(val) ?? 0.0;
                        billingNotifier.updateDiscount(d);
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E293B),
                      value: billingState.paymentType,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.payment, color: Colors.cyanAccent),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Full', child: Text('Full Payment')),
                        DropdownMenuItem(value: 'Partial', child: Text('Partial Payment')),
                        DropdownMenuItem(value: 'Borrow', child: Text('Borrow / Credit')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          billingNotifier.updatePaymentType(val);
                        }
                      },
                    ),
                    if (billingState.paymentType == 'Partial') ...[
                      const SizedBox(height: 15),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Paid Amount (Rs)',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.money, color: Colors.greenAccent),
                        ),
                        onChanged: (val) {
                          double amount = double.tryParse(val) ?? 0.0;
                          billingNotifier.updatePaidAmount(amount);
                        },
                      ),
                    ],
                    if (billingState.paymentType != 'Full') ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<int>(
                        dropdownColor: const Color(0xFF1E293B),
                        value: 15,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Due Period',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.calendar_today, color: Colors.orangeAccent),
                        ),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 Days')),
                          DropdownMenuItem(value: 15, child: Text('15 Days')),
                          DropdownMenuItem(value: 30, child: Text('30 Days')),
                        ],
                        onChanged: (days) {
                          if (days != null) {
                            billingNotifier.updateDueDate(DateTime.now().add(Duration(days: days)));
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(color: Colors.white70)),
                        Text('Rs ${billingState.subTotal}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
// GST row removed
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill Amount:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'Rs ${billingState.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    if (billingState.paymentType != 'Full') ...[
                      const Divider(color: Colors.white24, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paid Amount:', style: TextStyle(color: Colors.greenAccent)),
                          Text(
                            'Rs ${billingState.calculatedPaidAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Remaining Dues:', style: TextStyle(color: Colors.redAccent)),
                          Text(
                            'Rs ${billingState.calculatedRemainingAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _generateBill,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF0072FF)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'GENERATE & PRINT BILL',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
