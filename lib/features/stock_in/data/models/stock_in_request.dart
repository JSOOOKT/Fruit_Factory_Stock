import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_in_request.freezed.dart';
part 'stock_in_request.g.dart';

@freezed
class StockInRequest with _$StockInRequest {
  const factory StockInRequest({
    required String dateReceived,
    required String senderName,
    required String productCode,
    required double quantityKg,
    required String shift,
    String? note,
  }) = _StockInRequest;

  factory StockInRequest.fromJson(Map<String, dynamic> json) =>
      _$StockInRequestFromJson(json);
}

@freezed
class VoiceInputData with _$VoiceInputData {
  const factory VoiceInputData({
    required String rawText,
    required String dateReceived,
    required String senderName,
    required String productCode,
    required double quantityKg,
    required double confidence,
    String? note,
  }) = _VoiceInputData;

  factory VoiceInputData.fromJson(Map<String, dynamic> json) =>
      _$VoiceInputDataFromJson(json);
}

@freezed
class ManualEntryData with _$ManualEntryData {
  const factory ManualEntryData({
    required String dateReceived,
    required String senderName,
    required String productCode,
    required double quantityKg,
    required String shift,
    String? note,
  }) = _ManualEntryData;

  factory ManualEntryData.fromJson(Map<String, dynamic> json) =>
      _$ManualEntryDataFromJson(json);
}
