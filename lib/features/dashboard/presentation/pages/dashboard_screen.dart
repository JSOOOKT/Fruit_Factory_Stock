// lib/features/dashboard/presentation/pages/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_providers.dart';
import '../widgets/summary_card.dart';
import '../widgets/low_stock_alerts.dart';
import '../widgets/stock_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _formatter = NumberFormat('#,##0.0', 'en_US');

  @override
  void initState() {
    super.initState();
    // Refresh dashboard on load
    Future.microtask(() {
      ref.refresh(dashboardSummaryProvider(ref.watch(dateFilterProvider)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(dateFilterProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(dashboardSummaryProvider(filter));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing dashboard...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(dashboardSummaryProvider(filter));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Total In',
                          value: '${_formatter.format(summary.totalStockIn)} KG',
                          icon: Icons.arrow_downward,
                          color: Colors.green,
                          subtitle: '${summary.totalEntries} entries',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SummaryCard(
                          title: 'Total Out',
                          value: '${_formatter.format(summary.totalStockOut)} KG',
                          icon: Icons.arrow_upward,
                          color: Colors.red,
                          subtitle: '${summary.totalEntries} entries',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Current Balance',
                          value: '${_formatter.format(summary.totalBalance)} KG',
                          icon: Icons.inventory_2,
                          color: summary.totalBalance < 0 ? Colors.red : Colors.blue,
                          subtitle: '${summary.totalProducts} products',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SummaryCard(
                          title: 'Products',
                          value: summary.totalProducts.toString(),
                          icon: Icons.category,
                          color: Colors.purple,
                          subtitle: 'Active products',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter info
                  if (filter.hasFilter) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filtered: ${filter.startDate != null ? DateFormat('dd/MM/yyyy').format(filter.startDate!) : 'Start'} - ${filter.endDate != null ? DateFormat('dd/MM/yyyy').format(filter.endDate!) : 'End'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              ref.read(dateFilterProvider.notifier).clearFilter();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Low Stock Alerts
                  const LowStockAlerts(threshold: 100),
                  const SizedBox(height: 16),

                  // Stock Chart
                  const StockChart(),
                  const SizedBox(height: 16),

                  // Product Summary Table
                  _buildProductTable(summary),

                  // Last updated
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Last updated: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(summary.lastUpdated)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading dashboard',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(dashboardSummaryProvider(filter));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTable(DashboardSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Product')),
                  DataColumn(
                    label: Text('In (KG)'),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Out (KG)'),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Balance (KG)'),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Status')),
                ],
                rows: summary.productSummaries.map((product) {
                  final status = product.balance <= 0
                      ? 'Out of Stock'
                      : product.balance <= 100
                          ? 'Low Stock'
                          : 'In Stock';
                  final statusColor = product.balance <= 0
                      ? Colors.red
                      : product.balance <= 100
                          ? Colors.orange
                          : Colors.green;

                  return DataRow(
                    cells: [
                      DataCell(Text(product.productCode)),
                      DataCell(Text(product.productName)),
                      DataCell(
                        Text(
                          product.totalIn.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          product.totalOut.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          product.balance.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: product.balance < 0 ? Colors.red : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final filter = ref.read(dateFilterProvider);
    DateTime? startDate = filter.startDate;
    DateTime? endDate = filter.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Dashboard'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    'Start Date: ${startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : 'Not set'}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    'End Date: ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : 'Not set'}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(dateFilterProvider.notifier).clearFilter();
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(dateFilterProvider.notifier).updateStartDate(startDate);
                  ref.read(dateFilterProvider.notifier).updateEndDate(endDate);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('Export as CSV'),
              subtitle: Text('Compatible with Excel'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Export as PDF'),
              subtitle: Text('Printable report'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}