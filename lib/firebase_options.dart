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
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
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

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCKy7t4KEhKmBeqGoVQTf_nve850Yg8USQ',
    appId: '1:583264542780:ios:4a789c137b3282ad2d6339',
    messagingSenderId: '583264542780',
    projectId: 'dog-collar-de15d',
    databaseURL: 'https://dog-collar-de15d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'dog-collar-de15d.firebasestorage.app',
    iosBundleId: 'com.example.mobileApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDU_Inu0pPT1NJ1PQ90DGsSoG3b-y8nH8I',
    appId: '1:583264542780:web:fc7e61f7bfddecc02d6339',
    messagingSenderId: '583264542780',
    projectId: 'dog-collar-de15d',
    authDomain: 'dog-collar-de15d.firebaseapp.com',
    databaseURL: 'https://dog-collar-de15d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'dog-collar-de15d.firebasestorage.app',
    measurementId: 'G-GXHB6KZVKX',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDU_Inu0pPT1NJ1PQ90DGsSoG3b-y8nH8I',
    appId: '1:583264542780:web:c8e9ae58e11ba1142d6339',
    messagingSenderId: '583264542780',
    projectId: 'dog-collar-de15d',
    authDomain: 'dog-collar-de15d.firebaseapp.com',
    databaseURL: 'https://dog-collar-de15d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'dog-collar-de15d.firebasestorage.app',
    measurementId: 'G-Q10ZJ9SKEZ',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCKy7t4KEhKmBeqGoVQTf_nve850Yg8USQ',
    appId: '1:583264542780:ios:4a789c137b3282ad2d6339',
    messagingSenderId: '583264542780',
    projectId: 'dog-collar-de15d',
    databaseURL: 'https://dog-collar-de15d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'dog-collar-de15d.firebasestorage.app',
    iosBundleId: 'com.example.mobileApp',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBElqBolDWuvqW9699ly-ccgVeZOdbM1zY',
    appId: '1:583264542780:android:dd33ca06562b34cb2d6339',
    messagingSenderId: '583264542780',
    projectId: 'dog-collar-de15d',
    databaseURL: 'https://dog-collar-de15d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'dog-collar-de15d.firebasestorage.app',
  );

}