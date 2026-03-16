import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';

/// Inicializamos Firebase 
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  /// Inicializa Firebase usando la configuración generada automáticamente
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      /// Tema global de la aplicación
      theme: AppTheme.lightTheme,

      /// Pantalla inicial
      home: const LoginScreen(),
    );
  }
}