import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/firebase_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intenta inicializar Firebase. En Android lee google-services.json
  // automáticamente. Si no hay configuración válida (p. ej. en web sin
  // firebase_options), cae a modo mock sin romper la app.
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(const ProviderScope(child: HidroSmartApp()));
}
