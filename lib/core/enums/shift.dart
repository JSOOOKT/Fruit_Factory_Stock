// lib/core/enums/shift.dart
enum Shift {
  morning,
  afternoon,
  night,
}

extension ShiftExtension on Shift {
  String get value {
    switch (this) {
      case Shift.morning:
        return 'morning';
      case Shift.afternoon:
        return 'afternoon';
      case Shift.night:
        return 'night';
    }
  }

  String get displayName {
    switch (this) {
      case Shift.morning:
        return 'เช้า';
      case Shift.afternoon:
        return 'บ่าย';
      case Shift.night:
        return 'ดึก';
    }
  }

  String get displayNameEn {
    switch (this) {
      case Shift.morning:
        return 'Morning';
      case Shift.afternoon:
        return 'Afternoon';
      case Shift.night:
        return 'Night';
    }
  }

  static Shift fromValue(String value) {
    return Shift.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => Shift.morning,
    );
  }
}