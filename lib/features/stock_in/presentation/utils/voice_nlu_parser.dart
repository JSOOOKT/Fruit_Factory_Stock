import 'package:intl/intl.dart';
import '../utils/stock_in_validators.dart';

class VoiceNLUParser {
  /// Parse Thai natural language input to structured stock in data
  /// Example: "รับเข้าจากยุทธนา วันที่ 10 ตุลาคม ฝา 2 สี หนึ่งร้อยกิโล"
  static ParsedVoiceData parseThaiVoiceInput(
    String input, {
    required Map<String, String> productCodeMap, // productName -> productCode
  }) {
    final errors = <String>[];
    String? senderName;
    String? dateReceived;
    String? productCode;
    double? quantityKg;

    // Normalize input
    final cleanInput = input.toLowerCase().trim();

    // 1. Extract sender name (usually first meaningful name after "จาก" or at beginning)
    // Look for pattern: "จาก{name}" or "ชื่อ{name}" or "จาก {name}"
    final senderMatch = RegExp(r'จาก\s+([ก-ฮ\w]+)').firstMatch(cleanInput);
    if (senderMatch != null) {
      senderName = senderMatch.group(1)!.trim();
    } else {
      // Try to extract first words before date/product indicators
      final firstWordsMatch = RegExp(r'^([ก-ฮ\w\s]+?)(?:วันที่|เมื่อ)').firstMatch(cleanInput);
      if (firstWordsMatch != null) {
        senderName = firstWordsMatch.group(1)!.trim();
      }
    }

    // 2. Extract date
    dateReceived = _extractThaiDate(cleanInput);

    // 3. Extract product name/code
    productCode = _extractProductCode(cleanInput, productCodeMap);
    if (productCode == null) {
      errors.add('Could not determine product type from voice input');
    }

    // 4. Extract quantity in Thai numerals
    quantityKg = _extractThaiQuantity(cleanInput);

    // Calculate confidence score
    double confidence = 0.0;
    if (senderName != null && senderName.isNotEmpty) confidence += 0.25;
    if (dateReceived != null && dateReceived.isNotEmpty) confidence += 0.25;
    if (productCode != null && productCode.isNotEmpty) confidence += 0.25;
    if (quantityKg != null && quantityKg > 0) confidence += 0.25;

    return ParsedVoiceData(
      senderName: senderName,
      dateReceived: dateReceived,
      productCode: productCode,
      quantityKg: quantityKg ?? 0.0,
      confidence: confidence,
      errors: errors,
      rawInput: input,
    );
  }

  /// Extract date from Thai text
  /// Supports: "วันที่ 10 ตุลาคม", "10/10/2567", etc.
  static String? _extractThaiDate(String input) {
    // Thai month names
    const thaiMonths = {
      'มกราคม': '01',
      'เมษายน': '04',
      'พฤษภาคม': '05',
      'มิถุนายน': '06',
      'กรกฎาคม': '07',
      'สิงหาคม': '08',
      'กันยายน': '09',
      'ตุลาคม': '10',
      'พฤศจิกายน': '11',
      'ธันวาคม': '12',
    };

    // Pattern: วันที่ 10 ตุลาคม (might include year)
    final thaiDateMatch = RegExp(r'วันที่\s+(\d{1,2})\s+([ก-ฮ]+)').firstMatch(input);
    if (thaiDateMatch != null) {
      final day = thaiDateMatch.group(1)!.padLeft(2, '0');
      final monthThai = thaiDateMatch.group(2)!;
      final month = thaiMonths[monthThai] ?? '01';
      
      // Try to find year in same input or default to current year
      final yearMatch = RegExp(r'(\d{4})').firstMatch(input);
      final year = yearMatch?.group(1) ?? DateTime.now().year.toString();
      
      return '$year-$month-$day';
    }

    // Pattern: 10/10/2567 (Thai year) or 10/10/2024
    final slashDateMatch = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(input);
    if (slashDateMatch != null) {
      var day = slashDateMatch.group(1)!.padLeft(2, '0');
      var month = slashDateMatch.group(2)!.padLeft(2, '0');
      var year = slashDateMatch.group(3)!;
      
      // Convert Thai Buddhist year to Gregorian if needed (year > 2500)
      if (int.parse(year) > 2500) {
        year = (int.parse(year) - 543).toString();
      }
      
      return '$year-$month-$day';
    }

    return null;
  }

  /// Extract product code/name from input
  static String? _extractProductCode(String input, Map<String, String> productCodeMap) {
    // Try exact product name match
    for (final entry in productCodeMap.entries) {
      if (input.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Try partial match (Thai product names are often compound)
    for (final entry in productCodeMap.entries) {
      final parts = entry.key.toLowerCase().split(' ');
      if (parts.every((part) => input.contains(part))) {
        return entry.value;
      }
    }

    return null;
  }

  /// Extract quantity from Thai numerals
  /// Supports: "หนึ่งร้อยกิโล", "100 กิโล", "ห้าสิบ", etc.
  static double? _extractThaiQuantity(String input) {
    // Thai numeral words
    const thaiNumbers = {
      'ศูนย์': 0, 'จำนวนศูนย์': 0,
      'หนึ่ง': 1, 'ชื่น': 1,
      'สอง': 2, 'เสี่ยว': 2,
      'สาม': 3,
      'สี่': 4, 'สุ่ม': 4,
      'ห้า': 5, 'ห้าสิบ': 50,
      'หก': 6,
      'เจ็ด': 7, 'เจ้ดสิบ': 70,
      'แปด': 8, 'แปดสิบ': 80,
      'เก้า': 9, 'เก้าสิบ': 90,
      'สิบ': 10, 'สิบ': 10,
      'ร้อย': 100, 'ร้อยสิบ': 110,
      'พัน': 1000, 'พันสอง': 2000,
      'หมื่น': 10000,
      'แสน': 100000,
      'ล้าน': 1000000,
    };

    // Try digit + unit pattern: "100 กิโล" or "100กิโล"
    final digitMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:กิโล|kg|KG)').firstMatch(input);
    if (digitMatch != null) {
      final numStr = digitMatch.group(1)!.replaceAll(',', '.');
      return double.tryParse(numStr) ?? 0.0;
    }

    // Thai word number patterns
    var result = 0.0;
    var multiplier = 1.0;

    for (final word in thaiNumbers.keys) {
      if (input.contains(word)) {
        result += thaiNumbers[word]! * multiplier;
      }
    }

    // If we found Thai numbers, use that result
    if (result > 0) return result;

    return null;
  }
}

class ParsedVoiceData {
  final String? senderName;
  final String? dateReceived;
  final String? productCode;
  final double quantityKg;
  final double confidence;
  final List<String> errors;
  final String rawInput;

  ParsedVoiceData({
    required this.senderName,
    required this.dateReceived,
    required this.productCode,
    required this.quantityKg,
    required this.confidence,
    required this.errors,
    required this.rawInput,
  });

  bool get isValid => errors.isEmpty && confidence >= 0.75;

  Map<String, dynamic> toJson() => {
    'senderName': senderName,
    'dateReceived': dateReceived,
    'productCode': productCode,
    'quantityKg': quantityKg,
    'confidence': confidence,
    'errors': errors,
    'rawInput': rawInput,
  };
}
