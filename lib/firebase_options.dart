// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD3E-DZUhGuKreJVqIhpDy-ypMglGYaKuY',
    authDomain: 'fruit-factory-stock-b2314.firebaseapp.com',
    projectId: 'fruit-factory-stock-b2314',
    storageBucket: 'fruit-factory-stock-b2314.firebasestorage.app',
    messagingSenderId: '120471330340',
    appId: '1:120471330340:web:a983a19344e0dacdcf82b1',
    measurementId: 'G-GDR992PERZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3E-DZUhGuKreJVqIhpDy-ypMglGYaKuY',
    appId: '1:120471330340:android:your_android_app_id',
    messagingSenderId: '120471330340',
    projectId: 'fruit-factory-stock-b2314',
    authDomain: 'fruit-factory-stock-b2314.firebaseapp.com',
    storageBucket: 'fruit-factory-stock-b2314.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3E-DZUhGuKreJVqIhpDy-ypMglGYaKuY',
    appId: '1:120471330340:ios:your_ios_app_id',
    messagingSenderId: '120471330340',
    projectId: 'fruit-factory-stock-b2314',
    authDomain: 'fruit-factory-stock-b2314.firebaseapp.com',
    storageBucket: 'fruit-factory-stock-b2314.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD3E-DZUhGuKreJVqIhpDy-ypMglGYaKuY',
    appId: '1:120471330340:ios:your_macos_app_id',
    messagingSenderId: '120471330340',
    projectId: 'fruit-factory-stock-b2314',
    authDomain: 'fruit-factory-stock-b2314.firebaseapp.com',
    storageBucket: 'fruit-factory-stock-b2314.firebasestorage.app',
  );
}