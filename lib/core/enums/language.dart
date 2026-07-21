// lib/core/enums/language.dart
enum Language {
  th,
  en,
}

extension LanguageExtension on Language {
  String get code {
    switch (this) {
      case Language.th:
        return 'th';
      case Language.en:
        return 'en';
    }
  }

  String get displayName {
    switch (this) {
      case Language.th:
        return 'ไทย';
      case Language.en:
        return 'English';
    }
  }

  static Language fromCode(String code) {
    return Language.values.firstWhere(
      (e) => e.code == code.toLowerCase(),
      orElse: () => Language.th,
    );
  }
}