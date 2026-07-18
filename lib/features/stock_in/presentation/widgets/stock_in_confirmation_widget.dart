import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/stock_in_response.dart';
import '../providers/stock_in_providers.dart';
import '../utils/voice_nlu_parser.dart';

class StockInConfirmationWidget extends ConsumerWidget {
  final ParsedVoiceData parsedData;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const StockInConfirmationWidget({
    Key? key,
    required this.parsedData,
    required this.onConfirm,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confidenceColor = parsedData.confidence >= 0.9
        ? Colors.green
        : parsedData.confidence >= 0.75
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Verify Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.2),
                      border: Border.all(color: confidenceColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Confidence: ${(parsedData.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: confidenceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Extracted Data
              _buildConfirmationItem(
                'Sender:',
                parsedData.senderName ?? 'Unknown',
                Icons.person,
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Date:',
                parsedData.dateReceived ?? 'Unknown',
                Icons.calendar_today,
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Product:',
                parsedData.productCode ?? 'Unknown',
                Icons.inventory_2,
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Quantity:',
                '${parsedData.quantityKg} KG',
                Icons.scale,
              ),
              if (parsedData.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Issues:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...parsedData.errors.map((error) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text(error)),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
