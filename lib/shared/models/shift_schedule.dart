import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_schedule.freezed.dart';
part 'shift_schedule.g.dart';

@freezed
class ShiftSchedule with _$ShiftSchedule {
  const ShiftSchedule._();

  const factory ShiftSchedule({
    required String id,
    required String userId,
    required DateTime date,
    required String shift, // 'Morning', 'Afternoon', 'Evening'
    String? userName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShiftSchedule;

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) =>
      _$ShiftScheduleFromJson(json);
}
