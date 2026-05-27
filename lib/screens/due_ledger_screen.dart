import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_due.dart';
import '../models/payment_record.dart';
import '../models/invoice.dart';
import '../providers/billing_state.dart';
import '../widgets/glass_container.dart';
import 'invoice_preview_screen.dart';

class DueLedgerScreen extends ConsumerStatefulWidget {
  const DueLedgerScreen({super.key});

  @override
  ConsumerState<DueLedgerScreen> createState() => _DueLedgerScreenState();
}

class _DueLedgerScreenState extends ConsumerState<DueLedgerScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Pending', 'Partial', 'Paid'

  void _showRepaymentDialog(BuildContext context, CustomerDue due) {
    final billingNotifier = ref.read(billingStateProvider.notifier);
    final billingState = ref.read(billingStateProvider);
    final amountController = TextEditingController(text: due.remainingAmount.toStringAsFixed(2));
    final notesController = TextEditingController();
    String paymentMethod = 'Cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.payment_rounded, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text('Record Repayment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${due.customerName}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Invoice #: ${due.invoiceNumber}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Outstanding Due: Rs ${due.remainingAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Divider(color: Colors.white24, height: 20),
                    TextField(
                      controller: amountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (Rs)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E293B),
                      value: paymentMethod,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            paymentMethod = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Notes (e.g. Paid via GPay)',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () async {
                    final amountStr = amountController.text.trim();
                    final payAmt = double.tryParse(amountStr) ?? 0.0;

                    if (payAmt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid payment amount')),
                      );
                      return;
                    }

                    if (payAmt > due.remainingAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Amount cannot exceed outstanding due of Rs ${due.remainingAmount.toStringAsFixed(2)}')),
                      );
                      return;
                    }

                    final updatedDuePaid = due.paidAmount + payAmt;
                    final updatedDueRemaining = due.remainingAmount - payAmt;
                    final updatedDueStatus = updatedDueRemaining <= 0 ? 'Paid' : 'Partial';

                    final updatedDue = CustomerDue(
                      id: due.id,
                      customerName: due.customerName,
                      customerPhone: due.customerPhone,
                      invoiceId: due.invoiceId,
                      invoiceNumber: due.invoiceNumber,
                      totalAmount: due.totalAmount,
                      paidAmount: updatedDuePaid,
                      remainingAmount: updatedDueRemaining,
                      date: due.date,
                      dueDate: due.dueDate,
                      status: updatedDueStatus,
                    );

                    final correspondingInvoice = billingState.invoices.firstWhere(
                      (inv) => inv.id == due.invoiceId,
                      orElse: () => Invoice(
                        id: due.invoiceId,
                        invoiceNumber: due.invoiceNumber,
                        customerName: due.customerName,
                        customerPhone: due.customerPhone,
                        items: [],
                        subTotal: due.totalAmount,
                        gstPercentage: 0,
                        gstAmount: 0,
                        discountAmount: 0,
                        grandTotal: due.totalAmount,
                        paymentStatus: updatedDueStatus,
                        date: due.date,
                        notes: '',
                      ),
                    );

                    final updatedInvoice = Invoice(
                      id: correspondingInvoice.id,
                      invoiceNumber: correspondingInvoice.invoiceNumber,
                      customerName: correspondingInvoice.customerName,
                      customerPhone: correspondingInvoice.customerPhone,
                      items: correspondingInvoice.items,
                      subTotal: correspondingInvoice.subTotal,
                      gstPercentage: correspondingInvoice.gstPercentage,
                      gstAmount: correspondingInvoice.gstAmount,
                      discountAmount: correspondingInvoice.discountAmount,
                      grandTotal: correspondingInvoice.grandTotal,
                      paymentStatus: updatedDueStatus,
                      date: correspondingInvoice.date,
                      notes: correspondingInvoice.notes,
                      paymentType: correspondingInvoice.paymentType,
                      paidAmount: correspondingInvoice.paidAmount + payAmt,
                      remainingAmount: updatedDueRemaining,
                      dueDate: correspondingInvoice.dueDate,
                    );

                    final payment = PaymentRecord(
                      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                      dueId: due.id,
                      invoiceNumber: due.invoiceNumber,
                      customerName: due.customerName,
                      paidAmount: payAmt,
                      date: DateTime.now(),
                      paymentMethod: paymentMethod,
                      notes: notesController.text.trim(),
                    );

                    Navigator.of(context).pop();

                    await billingNotifier.recordRepayment(
                      payment: payment,
                      due: updatedDue,
                      invoice: updatedInvoice,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Repayment recorded successfully!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sendWhatsAppReminder(CustomerDue due) async {
    final phone = due.customerPhone;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this customer.')),
      );
      return;
    }

    final message = "Hello *${due.customerName}*, this is a friendly reminder from *Sri Siva Gayathri Enterprizes*. You have a pending balance of *Rs ${due.remainingAmount.toStringAsFixed(2)}* for Invoice *${due.invoiceNumber}* dated ${DateFormat('dd-MMM-yyyy').format(due.date)}. Please clear it at your earliest convenience. Thank you!";
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final waPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    
    final uri = Uri.parse("https://wa.me/$waPhone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingStateProvider);
    final dateFormat = DateFormat('dd-MMM-yyyy');

    final filteredDues = billingState.customerDues.where((d) {
      final matchesSearch = d.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            d.customerPhone.contains(_searchQuery) ||
                            d.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'All'
          ? true
          : d.status.toLowerCase() == _statusFilter.toLowerCase();
          
      return matchesSearch && matchesStatus;
    }).toList();

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
          title: const Text('Customer Credit Ledger', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search customer or mobile...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                        fillColor: Colors.white.withOpacity(0.04),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1E293B),
                        value: _statusFilter,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        icon: const Icon(Icons.filter_list, color: Colors.cyanAccent),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Status')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                          DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _statusFilter = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredDues.isEmpty
                  ? Center(
                      child: Text(
                        'No ledger records found.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredDues.length,
                      itemBuilder: (context, idx) {
                        final due = filteredDues[idx];
                        final paidPercent = due.totalAmount > 0
                            ? (due.paidAmount / due.totalAmount)
                            : 0.0;
                        final statusLower = due.status.toLowerCase();
                        final statusColor = statusLower == 'paid'
                            ? Colors.greenAccent
                            : (statusLower == 'partial' ? Colors.orangeAccent : Colors.redAccent);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(due.customerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (due.customerPhone.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone, color: Colors.white50, size: 10),
                                              const SizedBox(width: 4),
                                              Text(due.customerPhone, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                            ],
                                          )
                                        ],
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
                                          ),
                                          child: Text(
                                            due.status.toUpperCase(),
                                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rs ${due.remainingAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        final invoice = billingState.invoices.firstWhere(
                                          (inv) => inv.id == due.invoiceId,
                                          orElse: () => Invoice(
                                            id: due.invoiceId,
                                            invoiceNumber: due.invoiceNumber,
                                            customerName: due.customerName,
                                            customerPhone: due.customerPhone,
                                            items: [],
                                            subTotal: due.totalAmount,
                                            gstPercentage: 0,
                                            gstAmount: 0,
                                            discountAmount: 0,
                                            grandTotal: due.totalAmount,
                                            paymentStatus: due.status,
                                            date: due.date,
                                            notes: '',
                                          ),
                                        );
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice)),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.receipt_long, color: Colors.cyanAccent, size: 12),
                                          const SizedBox(width: 4),
                                          Text(due.invoiceNumber, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, decoration: TextDecoration.underline)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Due: ${dateFormat.format(due.dueDate)}',
                                      style: const TextStyle(color: Colors.white50, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Paid: Rs ${due.paidAmount.toStringAsFixed(0)} / ${due.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white50, fontSize: 10)),
                                    Text('${(paidPercent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: paidPercent,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                    minHeight: 5,
                                  ),
                                ),
                                if (due.status.toLowerCase() != 'paid') ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.withOpacity(0.12),
                                            foregroundColor: Colors.greenAccent,
                                            side: const BorderSide(color: Colors.green, width: 0.5),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: () => _showRepaymentDialog(context, due),
                                          icon: const Icon(Icons.monetization_on, size: 14),
                                          label: const Text('REPAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      if (due.customerPhone.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.cyan.withOpacity(0.12),
                                              foregroundColor: Colors.cyanAccent,
                                              side: const BorderSide(color: Colors.cyan, width: 0.5),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () => _sendWhatsAppReminder(due),
                                            icon: const Icon(Icons.notifications_active, size: 14),
                                            label: const Text('REMIND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
