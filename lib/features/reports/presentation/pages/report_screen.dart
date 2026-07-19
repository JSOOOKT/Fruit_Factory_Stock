// lib/features/reports/presentation/pages/report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/report_providers.dart';
import '../services/export_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (value) async {
              final report = ref.read(reportSummaryProvider).valueOrNull;
              if (report != null) {
                setState(() => _isExporting = true);
                try {
                  if (value == 'excel') {
                    await ExportService.exportToExcel(report);
                  } else if (value == 'csv') {
                    await ExportService.exportToCSV(report);
                  } else if (value == 'pdf') {
                    await ExportService.exportToPDF(report);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
                  );
                }
                setState(() => _isExporting = false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'excel', child: Text('Export as Excel')),
              const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
            ],
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) {
          return _buildReportContent(context, report);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading report: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(reportSummaryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, ReportSummary report) {
    final formatter = NumberFormat('#,##0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Products',
                  report.totalProducts.toString(),
                  Icons.inventory_2,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Stock In',
                  formatter.format(report.totalStockIn),
                  Icons.arrow_downward,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Stock Out',
                  formatter.format(report.totalStockOut),
                  Icons.arrow_upward,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Balance',
                  formatter.format(report.currentStock),
                  Icons.balance,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Product Report Table
          Text(
            'Product Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('In'), numeric: true),
                  DataColumn(label: Text('Out'), numeric: true),
                  DataColumn(label: Text('Balance'), numeric: true),
                  DataColumn(label: Text('Unit')),
                ],
                rows: report.productReports.map((product) {
                  final balanceColor = product.balance < 10
                      ? Colors.red
                      : product.balance < 50
                          ? Colors.orange
                          : Colors.green;

                  return DataRow(
                    cells: [
                      DataCell(Text(product.code)),
                      DataCell(Text(product.name)),
                      DataCell(Text(formatter.format(product.stockIn))),
                      DataCell(Text(formatter.format(product.stockOut))),
                      DataCell(
                        Text(
                          formatter.format(product.balance),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: balanceColor,
                          ),
                        ),
                      ),
                      DataCell(Text(product.unit)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Daily Report
          Text(
            'Daily Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('In'), numeric: true),
                  DataColumn(label: Text('Out'), numeric: true),
                  DataColumn(label: Text('Net'), numeric: true),
                ],
                rows: report.dailyReports.map((day) {
                  final netColor = day.netChange >= 0 ? Colors.green : Colors.red;
                  final netText = day.netChange >= 0 ? '+${day.netChange}' : '${day.netChange}';

                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(day.date))),
                      DataCell(Text(formatter.format(day.stockIn))),
                      DataCell(Text(formatter.format(day.stockOut))),
                      DataCell(
                        Text(
                          netText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: netColor,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Footer
          Text(
            'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}