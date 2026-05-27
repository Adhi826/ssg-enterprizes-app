import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

// Company constants - Sri Siva Gayathri Enterprizes
const String kCompanyName = 'SRI SIVA GAYATHRI ENTERPRIZES';
const String kCompanyTagline = 'Water & Soft Drinks Distributors';
const String kCompanyAddress = 'Rajampalli';
const String kCompanyPhone1 = '7036657769';
const String kCompanyPhone2 = '9000990191';


class PdfService {
  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── HEADER ────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [PdfColors.blue900, PdfColors.cyan700],
                  ),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Row(
                  main: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          kCompanyName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          kCompanyTagline,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.cyan100),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Address: $kCompanyAddress',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                        ),
                        pw.Text(
                          'Ph: $kCompanyPhone1 / $kCompanyPhone2',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                        ),

                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          invoice.invoiceNumber,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          dateFormat.format(invoice.date),
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.cyan100),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // ─── BILL TO & PAYMENT STATUS ───────────────────
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        if (invoice.customerPhone.isNotEmpty)
                          pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                      ],
                    ),
                  ),
                  () {
                    final status = invoice.paymentStatus.toLowerCase();
                    PdfColor bgColor = PdfColor.fromHex('#FFEBEE');
                    PdfColor borderColor = PdfColor.fromHex('#F44336');
                    PdfColor textColor = PdfColor.fromHex('#C62828');
                    if (status == 'paid') {
                      bgColor = PdfColor.fromHex('#E8F5E9');
                      borderColor = PdfColor.fromHex('#4CAF50');
                      textColor = PdfColor.fromHex('#2E7D32');
                    } else if (status == 'partial') {
                      bgColor = PdfColor.fromHex('#FFF3E0');
                      borderColor = PdfColor.fromHex('#FF9800');
                      textColor = PdfColor.fromHex('#E65100');
                    }
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: bgColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: borderColor),
                      ),
                      child: pw.Text(
                        invoice.paymentStatus.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    );
                  }(),
                ],
              ),
              pw.SizedBox(height: 18),

              // ─── ITEMS TABLE ───────────────────────────────
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.5),
                  1: const pw.FlexColumnWidth(1.0),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(1.0),
                  4: const pw.FlexColumnWidth(1.3),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                    children: [
                      _tableHeader('Description'),
                      _tableHeader('Brand'),
                      _tableHeader('Type'),
                      _tableHeader('Qty', align: pw.TextAlign.center),
                      _tableHeader('Amount (₹)', align: pw.TextAlign.right),
                    ],
                  ),
                  // Item rows
                  ...invoice.items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final bg = idx.isEven ? PdfColors.grey50 : PdfColors.white;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        _tableCell(item.productName),
                        _tableCell(item.brandName),
                        _tableCell(item.stockType),
                        _tableCell('${item.quantity}', align: pw.TextAlign.center),
                        _tableCell('₹${item.total.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),

              // ─── TOTALS BLOCK ────────────────────────────
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Notes section
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.notes.isNotEmpty ? invoice.notes : 'Thank you for your business!',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Totals
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        _totalRow('Subtotal:', '₹${invoice.subTotal.toStringAsFixed(2)}'),
                        if (invoice.discountAmount > 0)
                          _totalRow('Discount:', '- ₹${invoice.discountAmount.toStringAsFixed(2)}', valueColor: PdfColors.green700),

                        pw.Divider(color: PdfColors.blue200, thickness: 1),
                        _totalRow(
                          'GRAND TOTAL:',
                          '₹${invoice.grandTotal.toStringAsFixed(2)}',
                          isBold: true,
                          fontSize: 13,
                          valueColor: PdfColors.blue900,
                        ),
                        if (invoice.paymentType != 'Full') ...[
                          pw.Divider(color: PdfColors.blue200, thickness: 1),
                          _totalRow(
                            'Paid Amount:',
                            '₹${invoice.paidAmount.toStringAsFixed(2)}',
                            valueColor: PdfColor.fromHex('#2E7D32'),
                          ),
                          _totalRow(
                            'Remaining Balance:',
                            '₹${invoice.remainingAmount.toStringAsFixed(2)}',
                            isBold: true,
                            valueColor: PdfColor.fromHex('#C62828'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // ─── FOOTER ───────────────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Authorized Signature: ___________________',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('For $kCompanyName', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text('$kCompanyAddress | Ph: $kCompanyPhone1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper: Table header cell
  static pw.Widget _tableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  // Helper: Table data cell
  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10, color: PdfColors.black), textAlign: align),
    );
  }

  // Helper: Total row widget
  static pw.Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
    PdfColor valueColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        main: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : null, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : null, color: valueColor)),
        ],
      ),
    );
  }

  static Future<void> printInvoice(Invoice invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice-${invoice.invoiceNumber}',
    );
  }

  static Future<void> shareInvoicePdf(Invoice invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Invoice-${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📄 Invoice ${invoice.invoiceNumber}\n${kCompanyName}\n${kCompanyAddress}\nPh: $kCompanyPhone1 / $kCompanyPhone2\nAmount: ₹${invoice.grandTotal.toStringAsFixed(2)}',
      subject: 'Invoice from Sri Siva Gayathri Enterprizes',
    );
  }
}
