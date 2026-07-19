class AppConstants {
  static const String appName = 'Fruit Factory Stock';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String stockInCollection = 'stock_in_entries';
  static const String stockOutCollection = 'stock_out_entries';
  
  // Roles
  static const List<String> roles = ['recorder', 'supervisor', 'manager', 'admin'];
  
  // Shifts
  static const List<String> shifts = ['morning', 'afternoon', 'night'];
  static const Map<String, String> shiftLabels = {
    'morning': 'เช้า',
    'afternoon': 'บ่าย',
    'night': 'ดึก',
  };
  
  // Validation
  static const double minQuantity = 0.1;
  static const double maxQuantity = 100000;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  
  // Low Stock Threshold
  static const double lowStockThreshold = 100.0;
}