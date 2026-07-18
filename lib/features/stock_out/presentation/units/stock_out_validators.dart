// lib/features/stock_out/presentation/utils/stock_out_validators.dart
class StockOutValidators {
  // Validate quantity - positive and max limit
  static String? validateQuantity(double? value) {
    if (value == null) {
      return 'Quantity is required';
    }
    if (value <= 0) {
      return 'Quantity must be greater than 0';
    }
    if (value > 1000000) {
      return 'Quantity cannot exceed 1,000,000 KG';
    }
    return null;
  }

  // Validate purpose
  static String? validatePurpose(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Purpose is required';
    }
    if (value.length > 200) {
      return 'Purpose must not exceed 200 characters';
    }
    return null;
  }

  // Validate product code
  static String? validateProductCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product code is required';
    }
    return null;
  }

  // Validate optional note
  static String? validateNote(String? value) {
    if (value != null && value.length > 500) {
      return 'Note must not exceed 500 characters';
    }
    return null;
  }

  // Validate date
  static String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Invalid date format';
    }
  }
}