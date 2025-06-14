// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyCI7DRo84flPMEck-vby59jLxCYs8rzlfE',
    appId: '1:470723742181:web:13ef4ad394697b75d1870c',
    messagingSenderId: '470723742181',
    projectId: 'fir-ba08d',
    authDomain: 'fir-ba08d.firebaseapp.com',
    storageBucket: 'fir-ba08d.firebasestorage.app',
    measurementId: 'G-YWK4VSCT4P',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCI7DRo84flPMEck-vby59jLxCYs8rzlfE',
    appId: '1:470723742181:web:c7e8cfe0bb1cba73d1870c',
    messagingSenderId: '470723742181',
    projectId: 'fir-ba08d',
    authDomain: 'fir-ba08d.firebaseapp.com',
    storageBucket: 'fir-ba08d.firebasestorage.app',
    measurementId: 'G-BRTBKEJG21',
  );
}
