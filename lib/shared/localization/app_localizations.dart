import 'package:easy_localization/easy_localization.dart';

/// Centralized localization service
/// Usage: AppLocalizations.tr('key.path')
class AppLocalizations {
  static String tr(String key) {
    return key.tr();
  }

  static String get appName => 'app_name'.tr();
  static String get appVersion => 'app_version'.tr();

  // Common
  static String get confirm => 'common.confirm'.tr();
  static String get cancel => 'common.cancel'.tr();
  static String get save => 'common.save'.tr();
  static String get edit => 'common.edit'.tr();
  static String get delete => 'common.delete'.tr();
  static String get back => 'common.back'.tr();
  static String get next => 'common.next'.tr();
  static String get submit => 'common.submit'.tr();
  static String get ok => 'common.ok'.tr();
  static String get close => 'common.close'.tr();
  static String get search => 'common.search'.tr();
  static String get filter => 'common.filter'.tr();
  static String get add => 'common.add'.tr();
  static String get noData => 'common.no_data'.tr();

  // Home
  static String get homeTitle => 'home.title'.tr();
  static String get homeWelcome => 'home.welcome'.tr();
  static String get homeQuickActions => 'home.quick_actions'.tr();

  // Stock In
  static String get stockInTitle => 'stock_in.title'.tr();
  static String get senderName => 'stock_in.sender_name'.tr();
  static String get dateReceived => 'stock_in.date_received'.tr();
  static String get productCode => 'stock_in.product_code'.tr();
  static String get productType => 'stock_in.product_type'.tr();
  static String get quantityKg => 'stock_in.quantity_kg'.tr();
  static String get shift => 'stock_in.shift'.tr();
  static String get note => 'stock_in.note'.tr();
  static String get recordedBy => 'stock_in.recorded_by'.tr();
  static String get voiceEntry => 'stock_in.voice_entry'.tr();
  static String get manualEntry => 'stock_in.manual_entry'.tr();
  static String get confirmEntry => 'stock_in.confirm_entry'.tr();
  static String get editFields => 'stock_in.edit_fields'.tr();
  static String get recordAgain => 'stock_in.record_again'.tr();
  static String get entryHistory => 'stock_in.entry_history'.tr();

  // Stock Out
  static String get stockOutTitle => 'stock_out.title'.tr();
  static String get dateIssued => 'stock_out.date_issued'.tr();
  static String get purpose => 'stock_out.purpose'.tr();
  static String get insufficientStock => 'stock_out.insufficient_stock'.tr();
  static String get availableQuantity => 'stock_out.available_quantity'.tr();

  // Dashboard
  static String get dashboardTitle => 'dashboard.title'.tr();
  static String get summary => 'dashboard.summary'.tr();
  static String get totalIn => 'dashboard.total_in'.tr();
  static String get totalOut => 'dashboard.total_out'.tr();
  static String get balance => 'dashboard.balance'.tr();
  static String get lowStockAlert => 'dashboard.low_stock_alert'.tr();
  static String get byProduct => 'dashboard.by_product'.tr();
  static String get filterByDate => 'dashboard.filter_by_date'.tr();
  static String get filterBySender => 'dashboard.filter_by_sender'.tr();
  static String get filterByProduct => 'dashboard.filter_by_product'.tr();

  // Products
  static String get productsTitle => 'products.title'.tr();
  static String get nameTh => 'products.name_th'.tr();
  static String get nameEn => 'products.name_en'.tr();
  static String get unit => 'products.unit'.tr();
  static String get active => 'products.active'.tr();
  static String get addProduct => 'products.add_product'.tr();
  static String get editProduct => 'products.edit_product'.tr();
  static String get deleteProduct => 'products.delete_product'.tr();

  // Users
  static String get usersTitle => 'users.title'.tr();
  static String get name => 'users.name'.tr();
  static String get email => 'users.email'.tr();
  static String get role => 'users.role'.tr();
  static String get preferredLanguage => 'users.preferred_language'.tr();
  static String get addUser => 'users.add_user'.tr();
  static String get editUser => 'users.edit_user'.tr();
  static String get deleteUser => 'users.delete_user'.tr();
  static String get roleRecorder => 'users.role_recorder'.tr();
  static String get roleSupervisor => 'users.role_supervisor'.tr();
  static String get roleManager => 'users.role_manager'.tr();
  static String get roleAdmin => 'users.role_admin'.tr();

  // Settings
  static String get settingsTitle => 'settings.title'.tr();
  static String get language => 'settings.language'.tr();
  static String get thai => 'settings.thai'.tr();
  static String get english => 'settings.english'.tr();
  static String get theme => 'settings.theme'.tr();
  static String get light => 'settings.light'.tr();
  static String get dark => 'settings.dark'.tr();
  static String get about => 'settings.about'.tr();
  static String get logout => 'settings.logout'.tr();

  // Validation
  static String get required => 'validation.required'.tr();
  static String get invalidEmail => 'validation.invalid_email'.tr();
  static String get invalidQuantity => 'validation.invalid_quantity'.tr();
  static String get quantityMustBePositive => 'validation.quantity_must_be_positive'.tr();
  static String get quantityTooLarge => 'validation.quantity_too_large'.tr();
  static String get senderNameTooShort => 'validation.sender_name_too_short'.tr();
  static String get senderNameTooLong => 'validation.sender_name_too_long'.tr();

  // Errors
  static String get somethingWentWrong => 'errors.something_went_wrong'.tr();
  static String get networkError => 'errors.network_error'.tr();
  static String get serverError => 'errors.server_error'.tr();
  static String get unauthorized => 'errors.unauthorized'.tr();
  static String get notFound => 'errors.not_found'.tr();
  static String get tryAgain => 'errors.try_again'.tr();

  // Voice
  static String get tapToRecord => 'voice.tap_to_record'.tr();
  static String get recording => 'voice.recording'.tr();
  static String get processing => 'voice.processing'.tr();
  static String get noSpeechDetected => 'voice.no_speech_detected'.tr();
  static String get speechNotRecognized => 'voice.speech_not_recognized'.tr();
}
