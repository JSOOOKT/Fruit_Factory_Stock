// lib/features/stock_out/presentation/pages/stock_out_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stock_out_providers.dart';

class StockOutHistoryScreen extends ConsumerWidget {
  const StockOutHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockOutAsync = ref.watch(stockOutListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Out History'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: stockOutAsync.when(
        data: (stockOuts) {
          if (stockOuts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No stock out records', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stockOuts.length,
            itemBuilder: (context, index) {
              final item = stockOuts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: Text(item.productCode[0].toUpperCase()),
                  ),
                  title: Text(item.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${item.productCode}'),
                      Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(item.date)}'),
                      if (item.purpose != null) Text('Purpose: ${item.purpose}'),
                      if (item.note != null) Text('Note: ${item.note}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '-${item.quantity} ${item.unit}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'By: ${item.recordedBy}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading stock out: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(stockOutListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}