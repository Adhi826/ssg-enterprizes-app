import '../models/product.dart';
import '../models/invoice.dart';

class AiInsightsService {
  static List<String> generateDashboardSummaries(List<Product> products, List<Invoice> invoices) {
    List<String> insights = [];

    // Rule 1: Empty or critical stock alert
    final outOfStockCount = products.where((p) => p.quantity == 0).length;
    final lowStockCount = products.where((p) => p.isLowStock && p.quantity > 0).length;

    if (outOfStockCount > 0) {
      insights.add('⚠️ Critical: $outOfStockCount product(s) are completely out of stock. Restock immediately to capture lost sales.');
    } else if (lowStockCount > 0) {
      insights.add('⚡ Restock Alert: $lowStockCount product(s) are below threshold level. Consider placing orders today.');
    }

    // Rule 2: Top Selling Category insight
    double waterSales = 0;
    double sodaSales = 0;
    for (var inv in invoices) {
      for (var item in inv.items) {
        final prodList = products.where((p) => p.id == item.productId);
        if (prodList.isNotEmpty) {
          final prod = prodList.first;
          if (prod.category == 'Water') {
            waterSales += item.total;
          } else {
            sodaSales += item.total;
          }
        }
      }
    }

    if (waterSales > 0 || sodaSales > 0) {
      if (waterSales > sodaSales) {
        insights.add('📈 Trend: Mineral water brands account for the majority of your revenue this week. Maintain stock level.');
      } else {
        insights.add('📈 Trend: Soft drinks / Cool drinks are driving higher margins. Optimize cooler placements.');
      }
    } else {
      insights.add('💡 Tip: Try scanning barcodes to add products faster and minimize manual entry errors.');
    }

    // Rule 3: Payment insight
    final pendingCount = invoices.where((i) => i.paymentStatus.toLowerCase() != 'paid').length;
    if (pendingCount > 0) {
      insights.add('💳 Outstanding: There are $pendingCount invoice(s) with pending dues. Check the credit ledger to follow up.');
    } else {
      insights.add('🎉 Healthy Cashflow: All recent invoices have been successfully paid. Keep it up!');
    }

    return insights;
  }

  static String predictRunOutDays(Product product) {
    if (product.quantity == 0) return 'Immediate replenishment required';
    
    // Simulating average daily demand
    double averageDailyDemand = 0.0;
    if (product.category == 'Water') {
      averageDailyDemand = 8.5; // High demand
    } else {
      averageDailyDemand = 4.2; // Medium demand
    }

    double daysLeft = product.quantity / averageDailyDemand;
    if (daysLeft < 1) {
      return 'Less than 1 day left';
    } else if (daysLeft < 3) {
      return 'Approx. ${daysLeft.toStringAsFixed(1)} days left (Critical)';
    } else {
      return 'Approx. ${daysLeft.toStringAsFixed(0)} days left';
    }
  }
}
