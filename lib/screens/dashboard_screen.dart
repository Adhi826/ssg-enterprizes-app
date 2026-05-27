import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_state.dart';
import '../providers/inventory_state.dart';
import '../providers/billing_state.dart';
import '../services/ai_insights_service.dart';
import '../widgets/glass_container.dart';

import 'product_management_screen.dart';
import 'stock_entry_screen.dart';
import 'billing_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'due_ledger_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardOverviewTab(),
    const ProductManagementScreen(),
    const StockEntryScreen(),
    const BillingScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F2027),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
            )
          ]
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0F2027),
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white50,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off_rounded), label: 'Stock Logs'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Billing'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryStateProvider);
    final billingState = ref.watch(billingStateProvider);
    final authState = ref.watch(authStateProvider);
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');

    // Stats calculations
    int totalProducts = invState.products.length;
    int totalStock = invState.products.fold(0, (sum, p) => sum + p.quantity);
    final lowStockProducts = invState.products.where((p) => p.isLowStock).toList();
    int lowStockAlertCount = lowStockProducts.length;

    // Daily stock details calculation
    final now = DateTime.now();
    int incomingToday = invState.stockEntries
        .where((s) => s.type == 'Incoming' && s.dateTime.year == now.year && s.dateTime.month == now.month && s.dateTime.day == now.day)
        .fold(0, (sum, s) => sum + s.quantity);
    int outgoingToday = invState.stockEntries
        .where((s) => s.type == 'Outgoing' && s.dateTime.year == now.year && s.dateTime.month == now.month && s.dateTime.day == now.day)
        .fold(0, (sum, s) => sum + s.quantity);

    // Customer Credit calculations
    final activeDues = billingState.customerDues.where((d) => d.status.toLowerCase() != 'paid' && d.remainingAmount > 0).toList();
    final double totalDuesAmt = activeDues.fold(0.0, (sum, d) => sum + d.remainingAmount);
    final int pendingCustomers = activeDues.length;

    // AI summary advice
    List<String> aiSummaries = AiInsightsService.generateDashboardSummaries(
      invState.products,
      billingState.invoices,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sri Siva Gayathri Enterprizes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Water & Soft Drinks Distributor Dashboard',
                style: TextStyle(fontSize: 11, color: Colors.cyanAccent.withOpacity(0.8)),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined, color: Colors.cyanAccent),
              onPressed: () {
                if (lowStockAlertCount > 0) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: const Text('⚠️ Low Stock Alert', style: TextStyle(color: Colors.redAccent)),
                      content: Text('There are $lowStockAlertCount products with stock below threshold level. Please check product list.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
                        )
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All stock levels are healthy!')),
                  );
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${authState.userName.isNotEmpty ? authState.userName.split(' ').first : 'Admin'}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 5),
              const Text(
                'Overview of inventory status & recent sales bills',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 18),

              if (lowStockAlertCount > 0) ...[
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Low Stock Alert Notification',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '$lowStockAlertCount item(s) running out of stock! Restock suggested.',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 14),
                      ],
                    ),
                  ),
                ),
              ],

              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.category_rounded, color: Colors.cyanAccent, size: 20),
                          ),
                          const SizedBox(height: 12),
                          const Text('Total Products', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$totalProducts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.layers_rounded, color: Colors.orangeAccent, size: 20),
                          ),
                          const SizedBox(height: 12),
                          const Text('Available Stock', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$totalStock units', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.greenAccent, size: 20),
                          ),
                          const SizedBox(height: 12),
                          const Text('Stock In Today', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('+$incomingToday units', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_bag_rounded, color: Colors.pinkAccent, size: 20),
                          ),
                          const SizedBox(height: 12),
                          const Text('Stock Out Today', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('-$outgoingToday units', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Customer Credit & Borrow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DueLedgerScreen()),
                        );
                      },
                      child: GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.hand_holding_dollar_rounded, color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(height: 12),
                            const Text('Total Dues', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('Rs ${totalDuesAmt.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DueLedgerScreen()),
                        );
                      },
                      child: GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.people_alt_rounded, color: Colors.orangeAccent, size: 20),
                            ),
                            const SizedBox(height: 12),
                            const Text('Pending Customers', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('$pendingCustomers', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              const Text('AI Business Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              ...aiSummaries.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GlassContainer(
                  padding: 12,
                  bgGradientColor1: Colors.white.withOpacity(0.04),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Billing Invoices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('See all', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),

              billingState.invoices.isEmpty
                  ? Center(
                      child: Text('No invoice bills issued yet.', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: billingState.invoices.take(3).length,
                      itemBuilder: (context, idx) {
                        final bill = billingState.invoices[idx];
                        final isPaid = bill.paymentStatus.toLowerCase() == 'paid';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GlassContainer(
                            child: Row(
                              children: [
                                Icon(Icons.receipt_rounded, color: isPaid ? Colors.greenAccent : Colors.redAccent),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(bill.customerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(dateFormat.format(bill.date), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Rs ${bill.grandTotal}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(
                                      bill.paymentStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: isPaid ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                )
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
