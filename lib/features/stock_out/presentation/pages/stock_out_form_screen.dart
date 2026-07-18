// lib/features/stock_out/presentation/pages/stock_out_form_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../data/models/stock_out_request.dart';
import '../providers/stock_out_providers.dart';
import '../utils/stock_out_validators.dart';
import '../utils/stock_out_voice_parser.dart';
import '../widgets/stock_out_confirmation_widget.dart';

class StockOutFormScreen extends ConsumerStatefulWidget {
  const StockOutFormScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockOutFormScreen> createState() =>
      _StockOutFormScreenState();
}

class _StockOutFormScreenState extends ConsumerState<StockOutFormScreen> {
  late TextEditingController _productCodeController;
  late TextEditingController _quantityController;
  late TextEditingController _purposeController;
  late TextEditingController _dateController;
  late TextEditingController _noteController;
  final _formKey = GlobalKey<FormState>();

  // Voice recording state
  bool _isRecording = false;
  bool _isProcessingVoice = false;
  String _voiceTranscript = '';
  ParsedVoiceData? _parsedVoiceData;

  // Voice service (will be replaced with actual implementation)
  Timer? _recordingTimer;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _productCodeController = TextEditingController();
    _quantityController = TextEditingController();
    _purposeController = TextEditingController();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _productCodeController.dispose();
    _quantityController.dispose();
    _purposeController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    _recordingTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  // ==================== VOICE ENTRY METHODS ====================

  Future<void> _startVoiceRecording() async {
    // TODO: Check microphone permission
    // TODO: Initialize speech-to-text

    setState(() {
      _isRecording = true;
      _isProcessingVoice = false;
      _voiceTranscript = '';
      _parsedVoiceData = null;
    });

    // Show recording indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: 8),
            Text('Listening... Speak your withdrawal'),
          ],
        ),
        duration: Duration(seconds: 10),
        backgroundColor: Colors.red,
      ),
    );

    // Simulate voice recording (remove this in production)
    _simulateRecording();
  }

  void _simulateRecording() {
    // Simulate recording for 3 seconds
    _recordingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _stopVoiceRecording();
      }
    });
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
      _isProcessingVoice = true;
    });

    _recordingTimer?.cancel();

    // Simulate processing delay
    _simulationTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _processVoiceInput();
      }
    });
  }

  void _processVoiceInput() {
    // Example voice input - in production, this comes from speech-to-text
    final simulatedInput = _generateSimulatedVoiceInput();

    setState(() {
      _voiceTranscript = simulatedInput;
    });

    // Get product map from products list
    final products = ref.read(activeProductsProvider).valueOrNull ?? [];
    final productCodeMap = {
      for (final p in products) p.nameTh: p.productCode,
      for (final p in products) p.nameEn: p.productCode,
    };

    // Parse voice input
    final parsedData = StockOutVoiceParser.parseThaiVoiceInput(
      simulatedInput,
      productCodeMap: productCodeMap,
    );

    setState(() {
      _parsedVoiceData = parsedData;
      _isProcessingVoice = false;
    });

    // If confidence is high, show confirmation dialog
    if (parsedData.confidence >= 0.75 && parsedData.isValid) {
      _showVoiceConfirmation(parsedData);
    } else {
      // Show low confidence warning
      _showLowConfidenceDialog(parsedData);
    }
  }

  String _generateSimulatedVoiceInput() {
    // Generate different inputs for variety
    final inputs = [
      "เบิกฝาแดง 200 กิโล เพื่อผลิต วันที่ ${DateTime.now().day} ${_getThaiMonth(DateTime.now().month)}",
      "เบิก 150 กิโล ฝา 2 สี สำหรับตัวอย่าง",
      "ถอนฝาขาวเหลือง 50 กิโล สูญเสีย",
      "เบิกฝาเหลือง 100 กิโล เพื่อส่งขาย",
      "เบิกฝาขาวแดง 75 กิโล เพื่อผลิต",
    ];
    return inputs[DateTime.now().second % inputs.length];
  }

  String _getThaiMonth(int month) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month - 1];
  }

  void _autoFillForm(ParsedVoiceData data) {
    if (data.productCode != null) {
      _productCodeController.text = data.productCode!;
      ref.read(stockOutFormProvider.notifier).updateProductCode(data.productCode!);
    }

    if (data.quantityKg > 0) {
      _quantityController.text = data.quantityKg.toString();
      ref.read(stockOutFormProvider.notifier).updateQuantityKg(data.quantityKg);
    }

    if (data.purpose != null) {
      _purposeController.text = data.purpose!;
      ref.read(stockOutFormProvider.notifier).updatePurpose(data.purpose!);
    }

    if (data.dateIssued != null) {
      _dateController.text = data.dateIssued!;
      ref.read(stockOutFormProvider.notifier).updateDateIssued(data.dateIssued!);
    }

    // Trigger validation
    _formKey.currentState?.validate();
  }

  void _showVoiceConfirmation(ParsedVoiceData data) {
    final productCode = data.productCode;
    if (productCode == null) {
      _showErrorDialog('Could not identify product');
      return;
    }

    // Get available balance (simulated - replace with actual balance check)
    final availableBalance = _getAvailableBalance(productCode);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.record_voice_over, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Voice Entry Detected'),
          ],
        ),
        content: StockOutConfirmationWidget(
          parsedData: data,
          availableBalance: availableBalance,
          onConfirm: () {
            Navigator.pop(context);
            _autoFillForm(data);
            // Auto-submit after a brief delay to show the form
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _submitForm();
              }
            });
          },
          onEdit: () {
            Navigator.pop(context);
            // Auto-fill but let user edit
            _autoFillForm(data);
          },
        ),
        contentPadding: EdgeInsets.zero,
        actions: const [],
      ),
    );
  }

  void _showLowConfidenceDialog(ParsedVoiceData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Recognition Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We had trouble understanding your voice input.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${data.rawInput}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 8),
            if (data.errors.isNotEmpty)
              ...data.errors.map((error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error)),
                      ],
                    ),
                  )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _parsedVoiceData = null;
                _voiceTranscript = '';
              });
              // Start recording again
              _startVoiceRecording();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  double _getAvailableBalance(String productCode) {
    // TODO: Get actual balance from database/stock service
    // For now, return a simulated value based on product code
    final hash = productCode.hashCode.abs();
    return 100 + (hash % 500).toDouble();
  }

  // ==================== DATE PICKER ====================

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      ref.read(stockOutFormProvider.notifier).updateDateIssued(_dateController.text);
    }
  }

  // ==================== FORM SUBMISSION ====================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid quantity')),
      );
      return;
    }

    final request = StockOutRequest(
      dateIssued: _dateController.text,
      productCode: _productCodeController.text,
      quantityKg: quantity,
      purpose: _purposeController.text,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    // Check stock availability
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // Show confirmation dialog
    _showConfirmationDialog(request, user.uid);
  }

  void _showConfirmationDialog(StockOutRequest request, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Stock Out'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfirmationItem('Product:', request.productCode),
              _buildConfirmationItem('Quantity:', '${request.quantityKg} KG'),
              _buildConfirmationItem('Purpose:', request.purpose),
              _buildConfirmationItem('Date:', request.dateIssued),
              if (request.note != null && request.note!.isNotEmpty)
                _buildConfirmationItem('Note:', request.note!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveEntry(request, userId, context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Confirm Withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, width: 100),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _saveEntry(StockOutRequest request, String userId, BuildContext context) async {
    Navigator.pop(context); // Close dialog

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Processing withdrawal...')),
    );

    await ref
        .read(stockOutNotifierProvider.notifier)
        .createStockOutEntry(request, userId);

    // Check for errors
    final state = ref.read(stockOutNotifierProvider);
    if (state.hasError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${state.error}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Stock out recorded successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    _productCodeController.clear();
    _quantityController.clear();
    _purposeController.clear();
    _noteController.clear();
    setState(() {
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _voiceTranscript = '';
      _parsedVoiceData = null;
      _isRecording = false;
      _isProcessingVoice = false;
    });

    // Navigate back to history
    Navigator.pop(context);
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Out - Withdraw'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          // Voice recording button
          IconButton(
            icon: _isRecording
                ? const Icon(Icons.stop_circle)
                : _isProcessingVoice
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.mic),
            onPressed: _isProcessingVoice
                ? null
                : _isRecording
                    ? _stopVoiceRecording
                    : _startVoiceRecording,
            tooltip: _isRecording ? 'Stop Recording' : 'Voice Input',
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Voice transcript (if any)
                if (_voiceTranscript.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.record_voice_over, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Voice Input:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                _voiceTranscript,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _voiceTranscript = '';
                              _parsedVoiceData = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product Code with dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Product Code',
                          hintText: 'Select product',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: products.map((product) {
                          return DropdownMenuItem(
                            value: product.productCode,
                            child: Row(
                              children: [
                                Text(product.productCode),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    product.nameTh,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _productCodeController.text = value ?? '';
                          ref
                              .read(stockOutFormProvider.notifier)
                              .updateProductCode(value ?? '');
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Product is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quantity
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity (KG)',
                          hintText: 'Enter quantity to withdraw',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixText: 'KG',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          final qty = double.tryParse(value) ?? 0.0;
                          ref
                              .read(stockOutFormProvider.notifier)
                              .updateQuantityKg(qty);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quantity is required';
                          }
                          final qty = double.tryParse(value);
                          if (qty == null) {
                            return 'Invalid quantity';
                          }
                          return StockOutValidators.validateQuantity(qty);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Purpose
                      TextFormField(
                        controller: _purposeController,
                        decoration: InputDecoration(
                          labelText: 'Purpose',
                          hintText: 'e.g., Production, Waste, Sample',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          ref
                              .read(stockOutFormProvider.notifier)
                              .updatePurpose(value);
                        },
                        validator: StockOutValidators.validatePurpose,
                      ),
                      const SizedBox(height: 16),

                      // Date Issued
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Date Issued',
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        readOnly: true,
                        onChanged: (value) {
                          ref
                              .read(stockOutFormProvider.notifier)
                              .updateDateIssued(value);
                        },
                        validator: StockOutValidators.validateDate,
                      ),
                      const SizedBox(height: 16),

                      // Note (Optional)
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Note (Optional)',
                          hintText: 'Add additional notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          ref
                              .read(stockOutFormProvider.notifier)
                              .updateNote(value);
                        },
                        validator: StockOutValidators.validateNote,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Withdraw Stock',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading products: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(activeProductsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}