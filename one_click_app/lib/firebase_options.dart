import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCxawLrvYzJKo-XOHg1b9TSX6A7ssrYYxI',
    appId: '1:681496090649:web:79e8018f4d123ac3513288',
    messagingSenderId: '681496090649',
    projectId: 'one-click-1f83c',
    authDomain: 'one-click-1f83c.firebaseapp.com',
    storageBucket: 'one-click-1f83c.firebasestorage.app',
    measurementId: 'G-YK57VB5XVJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCxawLrvYzJKo-XOHg1b9TSX6A7ssrYYxI',
    appId: '1:681496090649:android:79e8018f4d123ac3513288', // Placeholder logic since android builds will use google-services.json anyways, but required for fallback.
    messagingSenderId: '681496090649',
    projectId: 'one-click-1f83c',
    storageBucket: 'one-click-1f83c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCxawLrvYzJKo-XOHg1b9TSX6A7ssrYYxI',
    appId: '1:681496090649:ios:79e8018f4d123ac3513288',
    messagingSenderId: '681496090649',
    projectId: 'one-click-1f83c',
    storageBucket: 'one-click-1f83c.firebasestorage.app',
    iosBundleId: 'com.example.oneClickApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCxawLrvYzJKo-XOHg1b9TSX6A7ssrYYxI',
    appId: '1:681496090649:ios:79e8018f4d123ac3513288',
    messagingSenderId: '681496090649',
    projectId: 'one-click-1f83c',
    storageBucket: 'one-click-1f83c.firebasestorage.app',
    iosBundleId: 'com.example.oneClickApp',
  );
}
