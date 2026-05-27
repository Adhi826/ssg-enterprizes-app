import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/invoice.dart';

class ExcelService {
  static Future<void> exportInventoryReport(List<Product> products) async {
    // Create an Excel document
    final xls.Workbook workbook = xls.Workbook();
    // Accessing sheet 1
    final xls.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Stock Status';

    // Set headers
    sheet.getRangeByIndex(1, 1).setText('Product ID');
    sheet.getRangeByIndex(1, 2).setText('Product Name');
    sheet.getRangeByIndex(1, 3).setText('Brand');
    sheet.getRangeByIndex(1, 4).setText('Category');
    sheet.getRangeByIndex(1, 5).setText('Unit Type');
    sheet.getRangeByIndex(1, 6).setText('Current Stock');
    sheet.getRangeByIndex(1, 7).setText('Min Quantity');
    sheet.getRangeByIndex(1, 8).setText('Price (Rs)');
    sheet.getRangeByIndex(1, 9).setText('Supplier');

    // Make headers bold
    final xls.Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#1F4E79';
    headerStyle.fontColor = '#FFFFFF';
    
    for (int i = 1; i <= 9; i++) {
      sheet.getRangeByIndex(1, i).cellStyle = headerStyle;
    }

    // Populate data
    for (int index = 0; index < products.length; index++) {
      final product = products[index];
      final row = index + 2;

      sheet.getRangeByIndex(row, 1).setText(product.id);
      sheet.getRangeByIndex(row, 2).setText(product.name);
      sheet.getRangeByIndex(row, 3).setText(product.brand);
      sheet.getRangeByIndex(row, 4).setText(product.category);
      sheet.getRangeByIndex(row, 5).setText(product.stockType);
      sheet.getRangeByIndex(row, 6).setNumber(product.quantity.toDouble());
      sheet.getRangeByIndex(row, 7).setNumber(product.minQuantity.toDouble());
      sheet.getRangeByIndex(row, 8).setNumber(product.price);
      sheet.getRangeByIndex(row, 9).setText(product.supplier);
    }

    // Save and launch the file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/Inventory_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final File file = File(path);
    await file.writeAsBytes(bytes);

    // Open file using open_file package
    await OpenFile.open(path);
  }

  static Future<void> exportSalesReport(List<Invoice> invoices) async {
    final xls.Workbook workbook = xls.Workbook();
    final xls.Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Sales Summary';

    // Headers
    sheet.getRangeByIndex(1, 1).setText('Invoice Number');
    sheet.getRangeByIndex(1, 2).setText('Date');
    sheet.getRangeByIndex(1, 3).setText('Customer Name');
    sheet.getRangeByIndex(1, 4).setText('Subtotal (Rs)');
    sheet.getRangeByIndex(1, 5).setText('Discount (Rs)');
    sheet.getRangeByIndex(1, 6).setText('Grand Total (Rs)');
    sheet.getRangeByIndex(1, 7).setText('Status');
    sheet.getRangeByIndex(1, 8).setText('Paid Amount (Rs)');
    sheet.getRangeByIndex(1, 9).setText('Remaining Amount (Rs)');
    sheet.getRangeByIndex(1, 10).setText('Payment Type');

    final xls.Style headerStyle = workbook.styles.add('salesHeaderStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#2E7D32';
    headerStyle.fontColor = '#FFFFFF';
    
    for (int i = 1; i <= 10; i++) {
      sheet.getRangeByIndex(1, i).cellStyle = headerStyle;
    }

    // Data
    final dateFormat = DateFormat('dd-MM-yyyy');
    double totalRevenue = 0.0;

    for (int index = 0; index < invoices.length; index++) {
      final invoice = invoices[index];
      final row = index + 2;

      sheet.getRangeByIndex(row, 1).setText(invoice.invoiceNumber);
      sheet.getRangeByIndex(row, 2).setText(dateFormat.format(invoice.date));
      sheet.getRangeByIndex(row, 3).setText(invoice.customerName);
      sheet.getRangeByIndex(row, 4).setNumber(invoice.subTotal);
      sheet.getRangeByIndex(row, 5).setNumber(invoice.discountAmount);
      sheet.getRangeByIndex(row, 6).setNumber(invoice.grandTotal);
      sheet.getRangeByIndex(row, 7).setText(invoice.paymentStatus);
      sheet.getRangeByIndex(row, 8).setNumber(invoice.paidAmount);
      sheet.getRangeByIndex(row, 9).setNumber(invoice.remainingAmount);
      sheet.getRangeByIndex(row, 10).setText(invoice.paymentType);

      totalRevenue += invoice.grandTotal;
    }

    // Total row
    final totalRow = invoices.length + 3;
    sheet.getRangeByIndex(totalRow, 3).setText('TOTAL REVENUE:');
    sheet.getRangeByIndex(totalRow, 3).cellStyle.bold = true;
    sheet.getRangeByIndex(totalRow, 6).setNumber(totalRevenue);
    sheet.getRangeByIndex(totalRow, 6).cellStyle.bold = true;

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final File file = File(path);
    await file.writeAsBytes(bytes);

    await OpenFile.open(path);
  }
}
