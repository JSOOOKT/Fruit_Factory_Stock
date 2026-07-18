// lib/features/stock_out/presentation/utils/stock_out_voice_parser.dart
import 'package:intl/intl.dart';

class StockOutVoiceParser {
  /// Parse Thai natural language input to structured stock out data
  /// Example: "เบิกฝาแดง 200 กิโล เพื่อผลิต"
  static ParsedVoiceData parseThaiVoiceInput(
    String input, {
    required Map<String, String> productCodeMap, // productName -> productCode
  }) {
    final errors = <String>[];
    String? productCode;
    double quantityKg = 0.0;
    String? purpose;
    String? dateIssued;

    // Normalize input
    final cleanInput = input.toLowerCase().trim();

    // 1. Extract product name/code
    productCode = _extractProductCode(cleanInput, productCodeMap);
    if (productCode == null) {
      errors.add('Could not determine product type from voice input');
    }

    // 2. Extract quantity
    quantityKg = _extractQuantity(cleanInput);
    if (quantityKg <= 0) {
      errors.add('Could not extract quantity from voice input');
    }

    // 3. Extract purpose
    purpose = _extractPurpose(cleanInput);
    if (purpose == null) {
      errors.add('Could not determine purpose from voice input');
    }

    // 4. Extract date (default to today)
    dateIssued = _extractDate(cleanInput) ?? 
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Calculate confidence score
    double confidence = 0.0;
    if (productCode != null && productCode.isNotEmpty) confidence += 0.30;
    if (quantityKg > 0) confidence += 0.30;
    if (purpose != null && purpose.isNotEmpty) confidence += 0.20;
    if (dateIssued != null && dateIssued.isNotEmpty) confidence += 0.20;

    return ParsedVoiceData(
      productCode: productCode,
      quantityKg: quantityKg,
      purpose: purpose,
      dateIssued: dateIssued,
      confidence: confidence,
      errors: errors,
      rawInput: input,
    );
  }

  /// Extract product code from input
  static String? _extractProductCode(
    String input,
    Map<String, String> productCodeMap,
  ) {
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
  static double _extractQuantity(String input) {
    // Thai numeral words
    const thaiNumbers = {
      'ศูนย์': 0,
      'หนึ่ง': 1,
      'สอง': 2,
      'สาม': 3,
      'สี่': 4,
      'ห้า': 5,
      'หก': 6,
      'เจ็ด': 7,
      'แปด': 8,
      'เก้า': 9,
      'สิบ': 10,
      'ร้อย': 100,
      'พัน': 1000,
      'หมื่น': 10000,
      'แสน': 100000,
      'ล้าน': 1000000,
    };

    // Try digit + unit pattern: "200 กิโล" or "200kg"
    final digitMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:กิโล|kg|KG)').firstMatch(input);
    if (digitMatch != null) {
      final numStr = digitMatch.group(1)!.replaceAll(',', '.');
      return double.tryParse(numStr) ?? 0.0;
    }

    // Try Thai number words pattern
    var result = 0.0;
    for (final word in thaiNumbers.keys) {
      if (input.contains(word)) {
        result += thaiNumbers[word]!;
      }
    }

    return result;
  }

  /// Extract purpose from input
  static String? _extractPurpose(String input) {
    // Common purpose keywords in Thai
    const purposeKeywords = [
      'ผลิต',
      'production',
      'สูญเสีย',
      'waste',
      'ตัวอย่าง',
      'sample',
      'ทดสอบ',
      'test',
      'ขาย',
      'sale',
      'ส่ง',
      'delivery',
    ];

    for (final keyword in purposeKeywords) {
      if (input.contains(keyword)) {
        return keyword;
      }
    }

    // Try to extract purpose phrase after "เพื่อ" or "สำหรับ"
    final purposeMatch = RegExp(r'(?:เพื่อ|สำหรับ)\s+([ก-ฮ\w\s]+)').firstMatch(input);
    if (purposeMatch != null) {
      return purposeMatch.group(1)!.trim();
    }

    return null;
  }

  /// Extract date from input
  static String? _extractDate(String input) {
    // Thai month names
    const thaiMonths = {
      'มกราคม': '01',
      'กุมภาพันธ์': '02',
      'มีนาคม': '03',
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

    // Pattern: วันที่ 10 ตุลาคม
    final thaiDateMatch = RegExp(r'วันที่\s+(\d{1,2})\s+([ก-ฮ]+)').firstMatch(input);
    if (thaiDateMatch != null) {
      final day = thaiDateMatch.group(1)!.padLeft(2, '0');
      final monthThai = thaiDateMatch.group(2)!;
      final month = thaiMonths[monthThai] ?? '01';
      
      // Try to find year or default to current year
      final yearMatch = RegExp(r'(\d{4})').firstMatch(input);
      final year = yearMatch?.group(1) ?? DateTime.now().year.toString();
      
      return '$year-$month-$day';
    }

    // Pattern: 10/10/2024
    final slashDateMatch = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(input);
    if (slashDateMatch != null) {
      final day = slashDateMatch.group(1)!.padLeft(2, '0');
      final month = slashDateMatch.group(2)!.padLeft(2, '0');
      final year = slashDateMatch.group(3)!;
      return '$year-$month-$day';
    }

    return null;
  }
}