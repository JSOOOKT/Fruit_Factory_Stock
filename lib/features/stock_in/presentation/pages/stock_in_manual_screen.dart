import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/stock_in_request.dart';
import '../providers/stock_in_providers.dart';
import '../utils/stock_in_validators.dart';

class StockInManualScreen extends ConsumerStatefulWidget {
  const StockInManualScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockInManualScreen> createState() =>
      _StockInManualScreenState();
}

class _StockInManualScreenState extends ConsumerState<StockInManualScreen> {
  late TextEditingController _senderNameController;
  late TextEditingController _dateReceivedController;
  late TextEditingController _productCodeController;
  late TextEditingController _quantityController;
  late TextEditingController _noteController;

  String _selectedShift = 'morning';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _senderNameController = TextEditingController();
    _dateReceivedController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _productCodeController = TextEditingController();
    _quantityController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _dateReceivedController.dispose();
    _productCodeController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      _dateReceivedController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _submitForm() async {
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

    final request = StockInRequest(
      dateReceived: _dateReceivedController.text,
      senderName: _senderNameController.text,
      productCode: _productCodeController.text,
      quantityKg: quantity,
      shift: _selectedShift,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    // Show confirmation dialog
    _showConfirmationDialog(request);
  }

  void _showConfirmationDialog(StockInRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Stock In Entry'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfirmationItem('Sender:', request.senderName),
              _buildConfirmationItem('Date:', request.dateReceived),
              _buildConfirmationItem('Product Code:', request.productCode),
              _buildConfirmationItem(
                'Quantity:',
                '${request.quantityKg} KG',
              ),
              _buildConfirmationItem('Shift:', request.shift),
              if (request.note != null)
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
            onPressed: () => _saveEntry(request, context),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _saveEntry(StockInRequest request, BuildContext context) async {
    Navigator.pop(context); // Close dialog

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving entry...')),
    );

    // TODO: Get current user ID from auth provider
    const userId = 'user-1'; // Placeholder

    await ref
        .read(stockInNotifierProvider.notifier)
        .createStockInEntry(request, userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved successfully!')),
      );
      _clearForm();
    }
  }

  void _clearForm() {
    _senderNameController.clear();
    _dateReceivedController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    _productCodeController.clear();
    _quantityController.clear();
    _noteController.clear();
    _selectedShift = 'morning';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock In - Manual Entry'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sender Name
              TextFormField(
                controller: _senderNameController,
                decoration: InputDecoration(
                  labelText: 'Sender Name',
                  hintText: 'Enter sender name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: StockInValidators.validateSenderName,
              ),
              const SizedBox(height: 16),

              // Date Received
              TextFormField(
                controller: _dateReceivedController,
                decoration: InputDecoration(
                  labelText: 'Date Received',
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
                validator: StockInValidators.validateDate,
              ),
              const SizedBox(height: 16),

              // Product Code
              TextFormField(
                controller: _productCodeController,
                decoration: InputDecoration(
                  labelText: 'Product Code',
                  hintText: 'e.g., RD-001, 2C-002',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: StockInValidators.validateProductCode,
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (KG)',
                  hintText: 'Enter quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'KG',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Quantity is required';
                  }
                  final qty = double.tryParse(value);
                  if (qty == null) {
                    return 'Invalid quantity';
                  }
                  return StockInValidators.validateQuantity(qty);
                },
              ),
              const SizedBox(height: 16),

              // Shift Selection
              DropdownButtonFormField<String>(
                value: _selectedShift,
                decoration: InputDecoration(
                  labelText: 'Shift',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'morning',
                    child: Text('Morning (เช้า)'),
                  ),
                  DropdownMenuItem(
                    value: 'afternoon',
                    child: Text('Afternoon (บ่าย)'),
                  ),
                  DropdownMenuItem(
                    value: 'night',
                    child: Text('Night (ดึก)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedShift = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Note (Optional)
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add any additional notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: StockInValidators.validateNote,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'Submit Stock In',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
