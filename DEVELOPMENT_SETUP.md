# Development Setup Guide

This guide provides detailed instructions for setting up your development environment for the Fruit Factory Stock app.

## System Requirements

- **OS**: macOS 12+, Linux (Ubuntu 20.04+), or Windows 10+
- **Flutter**: Version 3.0.0 or later
- **Dart**: Version 2.17.0 or later (included with Flutter)
- **Git**: Version 2.0 or later
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA

## Step 1: Install Flutter

### macOS
```bash
# Using Homebrew
brew install flutter

# Or download from https://flutter.dev/docs/get-started/install/macos
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### Linux
```bash
# Install dependencies
sudo apt-get install git curl zip unzip xz-utils clang cmake

# Download Flutter
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:$PWD/flutter/bin"
```

### Windows
- Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
- Extract to a permanent location (e.g., `C:\src\flutter`)
- Add `C:\src\flutter\bin` to PATH

## Step 2: Verify Flutter Installation

```bash
flutter doctor
```

This should show:
- ✓ Flutter (Channel stable)
- ✓ Dart SDK
- ✓ Android toolchain (if developing for Android)
- ✓ Xcode (if on macOS)

## Step 3: Clone Repository

```bash
git clone https://github.com/JSOOOKT/Fruit_Factory_Stock.git
cd Fruit_Factory_Stock
```

## Step 4: Install Dependencies

```bash
# Get Flutter packages
flutter pub get

# Install Firebase CLI (for deployment)
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Step 5: Configure Firebase

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project named "fruit-factory-stock-dev"
3. Enable Firestore Database
4. Enable Authentication (Email/Password, Google Sign-In)
5. Enable Storage (for attachments)

### Configure Firebase for Flutter

```bash
# From project root
flutterfire configure

# Select your Firebase project
# Select platforms: android, ios, web
```

This will generate `lib/firebase_options.dart` with your credentials.

### Alternative: Manual Configuration

If `flutterfire configure` doesn't work:

1. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console
2. Place files in:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

## Step 6: Run Code Generation

The project uses code generation for models (freezed), routing, and providers:

```bash
# Generate all code files
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch for changes during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

Generated files include:
- `*.freezed.dart` - Immutable data models
- `*.g.dart` - JSON serialization
- Router configuration

## Step 7: Set Up IDE

### VS Code Setup

1. Install extensions:
   - "Flutter" (by Dart Code)
   - "Dart" (by Dart Code)
   - "Awesome Flutter Snippets"

2. Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Fruit Factory Stock",
      "request": "launch",
      "type": "dart",
      "args": ["--verbose"]
    }
  ]
}
```

### Android Studio Setup

1. Open project in Android Studio
2. Click "Configure" → "Plugins"
3. Install Flutter and Dart plugins
4. Restart Android Studio

## Step 8: Configure Emulators/Devices

### Android
```bash
# List available Android emulators
flutter emulators

# Create emulator if needed
flutter emulators create --name emulator_name

# Launch emulator
flutter emulators launch emulator_name
```

### iOS (macOS only)
```bash
# Launch iOS Simulator
open -a Simulator

# Or use Flutter command
flutter run -d "iPhone 15"
```

### Physical Device
- Connect via USB
- Enable Developer Mode
- Install ADB drivers (Android)
- Run: `flutter devices`

## Step 9: First Run

```bash
# From project root
flutter run

# Or specify device
flutter run -d chrome  # Web
flutter run -d emulator-5554  # Android emulator
```

## Development Commands

### Code Quality

```bash
# Analyze code for issues
flutter analyze

# Format code (Dart style)
dart format lib/ test/

# Run linter
dart pub get && dart analyze --fatal-warnings

# Check for unused imports/variables
flutter pub global activate dartfmt
dartfmt -n lib/
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/stock_in/

# Generate coverage report
flutter test --coverage
lcov --list coverage/lcov.info  # View coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Building

```bash
# Debug build (fast, lots of debugging info)
flutter build apk --debug

# Release build (optimized)
flutter build apk --release

# iOS release
flutter build ipa --release
```

## Firestore Rules Setup

Create these security rules in Firebase Console:

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Authenticate all users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // Products: Admin only
    match /products/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin';
    }

    // Stock entries: Any authenticated user
    match /stock_in_entries/{document=**} {
      allow read, create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.recordedBy || request.auth.token.role in ['supervisor', 'admin'];
    }

    match /stock_out_entries/{document=**} {
      allow read, create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.recordedBy || request.auth.token.role in ['supervisor', 'admin'];
    }

    // Users: Only own data or admin
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid || request.auth.token.role == 'admin';
    }
  }
}
```

## Environment Variables

Create `.env` file (not tracked in git):

```env
FIREBASE_PROJECT_ID=fruit-factory-stock-dev
GOOGLE_CLOUD_SPEECH_API_KEY=your_api_key_here
DEBUG_LOGGING=true
```

Access in code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
```

## Troubleshooting

### Issue: "flutter: command not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:$PATH_TO_FLUTTER/bin"

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH="$PATH:$PATH_TO_FLUTTER/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: Code generation not working
```bash
# Clean and rebuild
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Firebase connection errors
- Verify `firebase_options.dart` has correct credentials
- Check Firestore is enabled in Firebase Console
- Verify security rules allow your app

### Issue: Voice input not recognized
- Ensure microphone permissions granted (iOS/Android)
- Check internet connection (for Cloud Speech API)
- Test with different language settings

### Issue: Can't connect to device
```bash
# List connected devices
flutter devices

# Restart adb (Android)
adb kill-server && adb start-server

# Reconnect USB
```

## Useful Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase + Flutter Guide](https://firebase.google.com/codelabs/firebase-get-to-know-flutter)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Navigation](https://pub.dev/packages/go_router)
- [Freezed Data Classes](https://pub.dev/packages/freezed)

## Next Steps

After setup:

1. Read the main [README.md](README.md) for architecture overview
2. Check `lib/features/stock_in/` for example feature structure
3. Review localization setup in `assets/i18n/`
4. Explore Firebase integration in `lib/shared/services/`

## Support

Having issues? Check:
1. Flutter Doctor output (`flutter doctor -v`)
2. Firebase Console for project details
3. This guide's Troubleshooting section
4. GitHub Issues on the repository

---

**Last Updated:** 18 July 2026
