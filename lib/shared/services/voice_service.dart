import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:logger/logger.dart';

/// Service for handling voice input and speech-to-text
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  
  late final stt.SpeechToText _speechToText;
  final Logger _logger = Logger();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLanguage = 'th-TH'; // Thai by default
  
  factory VoiceService() => _instance;
  
  VoiceService._internal() {
    _speechToText = stt.SpeechToText();
  }

  /// Initialize voice recognition (call once at app startup)
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: true,
      );
      _logger.i('Voice service initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      _logger.e('Failed to initialize voice service', error: e);
      return false;
    }
  }

  /// Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    try {
      return await _speechToText.locales();
    } catch (e) {
      _logger.e('Failed to get locales', error: e);
      return [];
    }
  }

  /// Set language for voice recognition
  /// Examples: 'th-TH' for Thai, 'en-US' for English
  Future<bool> setLanguage(String locale) async {
    try {
      final locales = await getLocales();
      final supported = locales.any((l) => l.localeId == locale);
      
      if (supported) {
        _currentLanguage = locale;
        _logger.i('Language set to: $locale');
        return true;
      } else {
        _logger.w('Locale not supported: $locale');
        return false;
      }
    } catch (e) {
      _logger.e('Failed to set language', error: e);
      return false;
    }
  }

  /// Start listening for speech
  /// [onResult] callback with recognized text
  Future<void> startListening({
    required Function(String recognizedText) onResult,
    Duration? listenDuration,
  }) async {
    if (!_isInitialized) {
      _logger.w('Voice service not initialized');
      return;
    }

    if (_isListening) {
      _logger.w('Already listening');
      return;
    }

    try {
      _isListening = true;
      
      await _speechToText.listen(
        onResult: (result) {
          _logger.d('Recognized text: ${result.recognizedWords}');
          onResult(result.recognizedWords);
        },
        listenFor: listenDuration ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: _currentLanguage,
        onSoundLevelChange: (level) {
          _logger.d('Sound level: $level');
        },
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      _logger.e('Error starting to listen', error: e);
      _isListening = false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      _isListening = false;
      await _speechToText.stop();
      _logger.i('Stopped listening');
    } catch (e) {
      _logger.e('Error stopping listen', error: e);
    }
  }

  /// Cancel current listening session
  Future<void> cancel() async {
    try {
      _isListening = false;
      await _speechToText.cancel();
      _logger.i('Cancelled listening');
    } catch (e) {
      _logger.e('Error cancelling listen', error: e);
    }
  }

  /// Get current listening status
  bool get isListening => _isListening;
  
  /// Get current language
  String get currentLanguage => _currentLanguage;

  /// Handle errors
  void _handleError(dynamic error) {
    _logger.e('Voice recognition error: $error');
    _isListening = false;
  }

  /// Handle status changes
  void _handleStatus(String status) {
    _logger.i('Voice recognition status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Dispose resources
  void dispose() {
    cancel();
  }
}

/// NLU (Natural Language Understanding) Service
/// Extracts structured data from free-form voice input
class NluService {
  static final NluService _instance = NluService._internal();
  final Logger _logger = Logger();

  factory NluService() => _instance;
  NluService._internal();

  /// Parse voice input into structured stock in entry
  /// Example: "รับเข้าจากยุทธนา วันที่ 10 ตุลาคม ฝา 2 สี หนึ่งร้อยกิโล"
  Future<ParsedStockInEntry?> parseStockInEntry(String input) async {
    try {
      // This is a placeholder - real implementation would use:
      // 1. Regular expressions for pattern matching
      // 2. Thai language NLP library
      // 3. Number word-to-digit conversion
      // 4. Date parsing
      
      _logger.i('Parsing input: $input');
      
      // TODO: Implement actual NLU parsing
      return null;
    } catch (e) {
      _logger.e('Error parsing stock in entry', error: e);
      return null;
    }
  }

  /// Parse voice input into structured stock out entry
  Future<ParsedStockOutEntry?> parseStockOutEntry(String input) async {
    try {
      _logger.i('Parsing output: $input');
      
      // TODO: Implement actual NLU parsing
      return null;
    } catch (e) {
      _logger.e('Error parsing stock out entry', error: e);
      return null;
    }
  }
}

/// Result of NLU parsing for stock in
class ParsedStockInEntry {
  final String? senderName;
  final DateTime? dateReceived;
  final String? productType;
  final double? quantityKg;
  final Map<String, double> confidence; // Field -> confidence score

  ParsedStockInEntry({
    this.senderName,
    this.dateReceived,
    this.productType,
    this.quantityKg,
    required this.confidence,
  });

  bool get isConfident => confidence.values.every((c) => c > 0.8);
}

/// Result of NLU parsing for stock out
class ParsedStockOutEntry {
  final String? productType;
  final double? quantityKg;
  final DateTime? dateIssued;
  final String? purpose;
  final Map<String, double> confidence;

  ParsedStockOutEntry({
    this.productType,
    this.quantityKg,
    this.dateIssued,
    this.purpose,
    required this.confidence,
  });

  bool get isConfident => confidence.values.every((c) => c > 0.8);
}
