class AppConstants {
  // API & Firebase
  static const String firebaseProjectId = 'fruit-factory-stock-dev';

  // App Info
  static const String appName = 'Fruit Factory Stock';
  static const String appVersion = '1.0.0';

  // Shifts
  static const List<String> shifts = ['Morning', 'Afternoon', 'Evening'];
  static const Map<String, String> shiftsLocalized = {
    'Morning': 'เช้า',
    'Afternoon': 'บ่าย',
    'Evening': 'ดึก',
  };

  // Roles
  static const List<String> userRoles = [
    'recorder',
    'supervisor',
    'manager',
    'admin'
  ];

  // Units
  static const String defaultUnit = 'KG';

  // Voice Recognition
  static const Duration voiceRecordingTimeout = Duration(seconds: 30);
  static const Duration voicePauseDuration = Duration(seconds: 3);

  // Validation
  static const int minSenderNameLength = 2;
  static const int maxSenderNameLength = 100;
  static const int minProductCodeLength = 2;
  static const int maxProductCodeLength = 10;
  static const double minQuantity = 0.1;
  static const double maxQuantity = 100000;

  // Default Low Stock Alert
  static const double defaultLowStockThreshold = 100;
}
