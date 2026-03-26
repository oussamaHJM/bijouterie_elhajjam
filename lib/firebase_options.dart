// PLACEHOLDER — Replace with real Firebase config from your Firebase console.
// Run: flutterfire configure
// or paste values from: https://console.firebase.google.com/

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
    apiKey: 'AIzaSyCe-YWG0SDYNDebKR93YKXaW4yyelZUGPc',
    appId: '1:1085914176415:web:b7839f3360fcf02552bbaa',
    messagingSenderId: '1085914176415',
    projectId: 'bijouterie-el-hajjam',
    authDomain: 'bijouterie-el-hajjam.firebaseapp.com',
    storageBucket: 'bijouterie-el-hajjam.firebasestorage.app',
  );

  // ⚠️ Replace ALL placeholder values below with real ones from Firebase console

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBoyw7mI_J_FFsLS6tUOGjagQDG_pXfG8o',
    appId: '1:1085914176415:android:c5fea23fef316b2b52bbaa',
    messagingSenderId: '1085914176415',
    projectId: 'bijouterie-el-hajjam',
    storageBucket: 'bijouterie-el-hajjam.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.bijouterie.elhajjam',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.bijouterie.elhajjam',
  );
}