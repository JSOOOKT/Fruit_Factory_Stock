// lib/features/stock_out/presentation/widgets/stock_out_confirmation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/stock_out_request.dart';
import '../providers/stock_out_providers.dart';

/// Widget to display and confirm stock out voice entry
class StockOutConfirmationWidget extends ConsumerWidget {
  final ParsedVoiceData parsedData;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final double availableBalance;

  const StockOutConfirmationWidget({
    Key? key,
    required this.parsedData,
    required this.onConfirm,
    required this.onEdit,
    required this.availableBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confidenceColor = parsedData.confidence >= 0.9
        ? Colors.green
        : parsedData.confidence >= 0.75
            ? Colors.orange
            : Colors.red;

    // Check if quantity exceeds available balance
    final isExceedingBalance = parsedData.quantityKg > availableBalance;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isExceedingBalance
              ? BorderSide(color: Colors.red, width: 2)
              : BorderSide.none,
        ),
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
                  Row(
                    children: [
                      const Text(
                        'Verify Withdrawal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (isExceedingBalance) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'INSUFFICIENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                'Product:',
                parsedData.productCode ?? 'Unknown',
                Icons.inventory_2,
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Quantity:',
                '${parsedData.quantityKg.toStringAsFixed(1)} KG',
                Icons.scale,
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Purpose:',
                parsedData.purpose ?? 'Not specified',
                Icons.info_outline,
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Date:',
                parsedData.dateIssued ?? DateTime.now().toIso8601String().split('T')[0],
                Icons.calendar_today,
              ),
              const SizedBox(height: 16),

              // Available Balance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExceedingBalance
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExceedingBalance ? Colors.red : Colors.green,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Balance:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${availableBalance.toStringAsFixed(1)} KG',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isExceedingBalance ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Errors / Issues
              if (parsedData.errors.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Issues:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...parsedData.errors.map((error) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(child: Text(error)),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Insufficient Stock Warning
              if (isExceedingBalance) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Insufficient Stock!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Requested: ${parsedData.quantityKg.toStringAsFixed(1)} KG\nAvailable: ${availableBalance.toStringAsFixed(1)} KG',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                    onPressed: isExceedingBalance ? null : onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExceedingBalance ? Colors.grey : Colors.red,
                      foregroundColor: Colors.white,
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

/// Parsed voice data for stock out
class ParsedVoiceData {
  final String? productCode;
  final double quantityKg;
  final String? purpose;
  final String? dateIssued;
  final double confidence;
  final List<String> errors;
  final String rawInput;

  ParsedVoiceData({
    this.productCode,
    required this.quantityKg,
    this.purpose,
    this.dateIssued,
    required this.confidence,
    this.errors = const [],
    this.rawInput = '',
  });

  bool get isValid => errors.isEmpty && confidence >= 0.75;

  Map<String, dynamic> toJson() => {
        'productCode': productCode,
        'quantityKg': quantityKg,
        'purpose': purpose,
        'dateIssued': dateIssued,
        'confidence': confidence,
        'errors': errors,
        'rawInput': rawInput,
      };
}