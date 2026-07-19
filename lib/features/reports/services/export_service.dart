import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/report_model.dart';

class ExportService {
  static Future<void> exportToExcel(ReportSummary report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Stock Report'];
    sheet.appendRow(['Product Code', 'Product Name', 'Stock In', 'Stock Out', 'Balance', 'Unit']);
    for (final product in report.productReports) {
      sheet.appendRow([product.code, product.name, product.stockIn, product.stockOut, product.balance, product.unit]);
    }
    sheet.appendRow([]);
    sheet.appendRow(['TOTAL', '', report.totalStockIn, report.totalStockOut, report.currentStock, '']);
    sheet.appendRow(['Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}']);
    final bytes = excel.save();
    if (bytes != null) {
      final tempFile = File('${Directory.systemTemp.path}/stock_report.xlsx');
      await tempFile.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Stock Report');
    }
  }

  static Future<void> exportToCSV(ReportSummary report) async {
    String csv = 'Product Code,Product Name,Stock In,Stock Out,Balance,Unit\n';
    for (final product in report.productReports) {
      csv += '${product.code},${product.name},${product.stockIn},${product.stockOut},${product.balance},${product.unit}\n';
    }
    csv += '\nTotal,,${report.totalStockIn},${report.totalStockOut},${report.currentStock},\n';
    csv += 'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}\n';
    final tempFile = File('${Directory.systemTemp.path}/stock_report.csv');
    await tempFile.writeAsString(csv);
    await Share.shareXFiles([XFile(tempFile.path)], text: 'Stock Report');
  }

  static Future<void> exportToPDF(ReportSummary report) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Stock Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 16),
              pw.Row(children: [
                _buildSummaryCard('Total Products', report.totalProducts.toString()),
                pw.SizedBox(width: 16),
                _buildSummaryCard('Total Stock In', report.totalStockIn.toString()),
                pw.SizedBox(width: 16),
                _buildSummaryCard('Total Stock Out', report.totalStockOut.toString()),
                pw.SizedBox(width: 16),
                _buildSummaryCard('Current Stock', report.currentStock.toString()),
              ]),
              pw.SizedBox(height: 24),
              pw.Text('Product Details'),
              pw.SizedBox(height: 8),
              _buildProductTable(report.productReports),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    final tempFile = File('${Directory.systemTemp.path}/stock_report.pdf');
    await tempFile.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(tempFile.path)], text: 'Stock Report');
  }

  static pw.Widget _buildSummaryCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(label, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
        ]),
      ),
    );
  }

  static pw.Widget _buildProductTable(List<ProductReport> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: ['Code', 'Name', 'Stock In', 'Stock Out', 'Balance', 'Unit'].map((text) {
            return pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          }).toList(),
        ),
        ...products.map((product) {
          return pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(product.code)),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(product.name)),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(product.stockIn.toString())),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(product.stockOut.toString())),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(product.balance.toString(), style: pw.TextStyle(color: product.balance < 10 ? PdfColors.red : null))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(product.unit)),
          ]);
        }),
      ],
    );
  }
}
