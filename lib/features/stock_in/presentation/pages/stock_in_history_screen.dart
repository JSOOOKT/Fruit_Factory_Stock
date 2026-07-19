// lib/features/stock_in/presentation/pages/stock_in_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stock_in_providers.dart';

class StockInHistoryScreen extends ConsumerWidget {
  const StockInHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockInAsync = ref.watch(stockInListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock In History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: stockInAsync.when(
        data: (stockIns) {
          if (stockIns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No stock in records', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stockIns.length,
            itemBuilder: (context, index) {
              final item = stockIns[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(item.productCode[0].toUpperCase()),
                  ),
                  title: Text(item.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${item.productCode}'),
                      Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(item.date)}'),
                      if (item.note != null) Text('Note: ${item.note}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '+${item.quantity} ${item.unit}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
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
              Text('Error loading stock in: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(stockInListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}