// lib/features/dashboard/presentation/widgets/low_stock_alerts.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';

class LowStockAlerts extends ConsumerWidget {
  final double threshold;

  const LowStockAlerts({Key? key, this.threshold = 100.0}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(lowStockAlertsProvider(threshold));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  'Threshold: ${threshold.toStringAsFixed(0)} KG',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            alertsAsync.when(
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('All products are well-stocked! 🎉'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return ListTile(
                      leading: Icon(
                        alert.isCritical
                            ? Icons.crisis_alert
                            : Icons.warning,
                        color: alert.isCritical ? Colors.red : Colors.orange,
                      ),
                      title: Text(
                        alert.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Code: ${alert.productCode}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${alert.currentBalance.toStringAsFixed(1)} ${alert.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: alert.isCritical ? Colors.red : Colors.orange,
                            ),
                          ),
                          Text(
                            'Threshold: ${alert.threshold} ${alert.unit}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading alerts: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}