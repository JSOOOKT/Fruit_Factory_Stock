# Fruit Factory Stock 🍌

A mobile-first Flutter application for digitizing paper-based stock management in fruit/papaya preservation factories. Features voice-to-data entry in Thai/English, real-time balance tracking, and comprehensive audit trails.

**Version:** 1.0.0  
**Status:** In Development  
**Tech Stack:** Flutter + Firebase + Riverpod

## Features ✨

- 🎤 **Voice Data Entry** - Speak to record stock movements (Thai/English)
- 📱 **Mobile-First Design** - Optimized for factory floor workers with large, easy-to-tap buttons
- 🌐 **Bilingual Support** - Full Thai/English UI and voice recognition
- ⚡ **Real-Time Calculations** - Automatic balance tracking with no calculation errors
- 📋 **Comprehensive Audit Trail** - Track who, when, and what for every transaction
- 📊 **Dashboard & Reports** - Visualize stock levels, export to Excel/PDF
- 🔐 **Role-Based Access** - Recorder, Supervisor, Manager, Admin roles
- 📡 **Offline Support** - Draft entries that sync when connection resumes

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── config/
│   ├── routes/              # Navigation & routing
│   └── theme/               # Theme configuration
├── core/
│   ├── constants/           # App-wide constants
│   ├── error/               # Error handling & failure types
│   ├── network/             # Network layer abstractions
│   ├── utils/               # Helper utilities
│   └── di/                  # Dependency injection setup
├── features/
│   ├── auth/                # Authentication feature
│   ├── stock_in/            # Stock In entry feature
│   ├── stock_out/           # Stock Out entry feature
│   ├── dashboard/           # Dashboard & reports
│   ├── product/             # Product management
│   ├── user/                # User management
│   └── settings/            # App settings
├── shared/
│   ├── models/              # Freezed data models
│   ├── providers/           # Riverpod state providers
│   ├── services/            # Shared services (Firebase, voice, etc.)
│   └── localization/        # Multilingual support
└── test/                    # Unit and widget tests

assets/
├── i18n/                    # Localization files (TH/EN)
├── icons/                   # App icons
├── images/                  # Static images
└── fonts/                   # Custom fonts
```

## Prerequisites

- Flutter SDK 3.0.0+
- Firebase account with Firestore enabled
- macOS/Linux (for development)

## Getting Started

### 1. Clone Repository
```bash
git clone https://github.com/JSOOOKT/Fruit_Factory_Stock.git
cd Fruit_Factory_Stock
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Code Generation (Models, Freezed, Routing)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (follow prompts)
flutterfire configure
```

Update `lib/firebase_options.dart` with your Firebase credentials.

### 5. Run the App
```bash
flutter run
```

## Development Workflow

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/stock_in/stock_in_test.dart
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Run linter
dart analyze --fatal-warnings
```

### Code Generation
```bash
# Watch for changes and rebuild
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Architecture

This project follows **Clean Architecture** with **Domain-Driven Design** principles:

- **Data Layer**: Firebase Firestore, local SQLite cache
- **Domain Layer**: Entities and business rules
- **Presentation Layer**: UI, Riverpod state management, routing with GoRouter

### State Management

Using **Riverpod** with code generation for:
- Provider scope management
- Dependency injection
- Reactive updates
- Type-safe state

### Voice Processing Pipeline

1. **Speech-to-Text**: Convert audio to text (Thai/English)
2. **NLU Intent Detection**: Identify entry type and slots
3. **Slot Filling**: Extract structured data (sender, date, product, quantity)
4. **Confirmation**: Display extracted data for user verification
5. **Persistence**: Save to Firestore with audit trail

## Database Schema

### Firestore Collections

```
products/
  {productCode}: {
    name_th, name_en, unit, active, createdAt, updatedAt
  }

stock_in_entries/
  {id}: {
    dateReceived, senderName, productCode, quantityKg,
    recordedBy, shift, note, createdAt, updatedAt, editedBy
  }

stock_out_entries/
  {id}: {
    dateIssued, productCode, quantityKg,
    recordedBy, purpose, createdAt, updatedAt
  }

users/
  {uid}: {
    name, email, role, preferredLanguage, active,
    createdAt, updatedAt, lastLoginAt
  }

shift_schedules/
  {id}: {
    userId, date, shift, createdAt, updatedAt
  }
```

## Deployment

### Android
```bash
flutter build apk
# or for release
flutter build appbundle
```

### iOS
```bash
flutter build ios
# or for release
flutter build ipa
```

### Web
```bash
flutter build web
# Deploy to Firebase Hosting
firebase deploy
```

## Contributing

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Commit changes: `git commit -am 'Add my feature'`
3. Push to branch: `git push origin feature/my-feature`
4. Submit a Pull Request

## Localization

To add new translations:

1. Edit `assets/i18n/th.json` for Thai
2. Edit `assets/i18n/en.json` for English
3. Access in UI:
   ```dart
   context.tr('key.nested.path')
   ```

## Voice Recognition Setup

Currently configured for:
- **Provider**: Google Cloud Speech-to-Text (configurable)
- **Languages**: Thai (primary), English (secondary)
- **Model**: Supports local accents

Configure in `lib/shared/services/voice_service.dart`.

## Troubleshooting

### Voice Input Not Working
- Check microphone permissions (iOS/Android)
- Verify internet connection
- Check language settings

### Firestore Connection Issues
- Verify Firebase credentials in `firebase_options.dart`
- Check Firestore security rules
- Verify network connectivity

### Code Generation Issues
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## License

This project is proprietary software developed for Fruit Factory.

## Support

For issues and questions, contact the development team or create an issue on GitHub.

---

**Last Updated:** 18 July 2026  
**Maintained by:** Development Team