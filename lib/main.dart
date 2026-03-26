import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase init may fail in dev if placeholder credentials are in use.
    // The app will still render the login screen.
    debugPrint('Firebase init failed (placeholder credentials?): $e');
  }

  runApp(const App());
}
