import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_state.dart';
import '../models/stock_history.dart';
import '../widgets/glass_container.dart';

class StockHistoryScreen extends ConsumerWidget {
  const StockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryStateProvider);
    final history = invState.stockHistory;
    final dateFormat = DateFormat('dd MMM yy, hh:mm a');

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
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 10),
              const Text('Stock History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('${history.length}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        body: history.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.08)),
                    const SizedBox(height: 16),
                    const Text('No History Yet', style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    const Text('Actions on products and stock will appear here', style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return _buildHistoryCard(item, dateFormat, index, history.length);
                },
              ),
      ),
    );
  }

  Widget _buildHistoryCard(StockHistory item, DateFormat dateFormat, int index, int total) {
    // Icon & color based on action type
    IconData icon;
    Color color;
    switch (item.actionType) {
      case 'Added':
        icon = Icons.add_circle;
        color = Colors.greenAccent;
        break;
      case 'Edited':
        icon = Icons.edit;
        color = Colors.cyanAccent;
        break;
      case 'Stock In':
        icon = Icons.arrow_downward_rounded;
        color = Colors.blueAccent;
        break;
      case 'Stock Out':
        icon = Icons.arrow_upward_rounded;
        color = Colors.orangeAccent;
        break;
      case 'Deleted':
        icon = Icons.delete;
        color = Colors.redAccent;
        break;
      case 'Restored':
        icon = Icons.restore;
        color = Colors.tealAccent;
        break;
      default:
        icon = Icons.info;
        color = Colors.white54;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            if (index < total - 1)
              Container(width: 2, height: 50, color: Colors.white.withOpacity(0.06)),
          ],
        ),
        const SizedBox(width: 14),
        // Card Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.actionType.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    Text(
                      dateFormat.format(item.timestamp),
                      style: const TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.productName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 13, color: Colors.white30),
                    const SizedBox(width: 4),
                    Text(item.userName, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const Spacer(),
                    if (item.actionType != 'Edited') ...[
                      Text(
                        '${item.previousStock}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 12, color: Colors.white24),
                      ),
                      Text(
                        '${item.updatedStock}',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes,
                    style: const TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
