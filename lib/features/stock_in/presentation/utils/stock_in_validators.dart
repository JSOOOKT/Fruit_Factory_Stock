class StockInValidators {
  // Validate sender name - not empty and max 100 chars
  static String? validateSenderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sender name is required';
    }
    if (value.length > 100) {
      return 'Sender name must not exceed 100 characters';
    }
    return null;
  }

  // Validate quantity - positive and max 1000000 KG (1000 tons)
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

  // Validate date - format YYYY-MM-DD or DD/MM/YYYY
  static String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      // Try Thai date format: DD/MM/YYYY
      final parts = value.split('/');
      if (parts.length == 3) {
        try {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          
          if (month < 1 || month > 12) {
            return 'Invalid month';
          }
          if (day < 1 || day > 31) {
            return 'Invalid day';
          }
          
          DateTime(year, month, day);
          return null;
        } catch (e) {
          return 'Invalid date format';
        }
      }
      return 'Date format should be YYYY-MM-DD or DD/MM/YYYY';
    }
  }

  // Parse date in various formats to standard YYYY-MM-DD
  static String parseDate(String dateString) {
    try {
      // Try standard format first
      final parsed = DateTime.parse(dateString);
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // Try Thai format DD/MM/YYYY
      final parts = dateString.split('/');
      if (parts.length == 3) {
        try {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          
          return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        } catch (e) {
          // Fallback to today
          return DateTime.now().toIso8601String().split('T')[0];
        }
      }
      // Fallback to today
      return DateTime.now().toIso8601String().split('T')[0];
    }
  }

  // Validate shift - must be one of: morning, afternoon, night
  static String? validateShift(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shift is required';
    }
    
    const validShifts = ['morning', 'afternoon', 'night', 'เช้า', 'บ่าย', 'ดึก'];
    if (!validShifts.contains(value)) {
      return 'Invalid shift';
    }
    return null;
  }

  // Normalize shift to standard format
  static String normalizeShift(String shift) {
    final shiftMap = {
      'เช้า': 'morning',
      'morning': 'morning',
      'บ่าย': 'afternoon',
      'afternoon': 'afternoon',
      'ดึก': 'night',
      'night': 'night',
    };
    return shiftMap[shift.toLowerCase()] ?? 'morning';
  }

  // Validate product code
  static String? validateProductCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product code is required';
    }
    if (value.length > 20) {
      return 'Product code must not exceed 20 characters';
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
}
