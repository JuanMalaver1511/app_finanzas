import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart'; 
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';

// Pantallas
import 'screens/login/login_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/activity_screen.dart';
import 'screens/admin/security_screen.dart';
import 'screens/profile/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFunctions.instanceFor(region: 'us-central1');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Tema global
      theme: AppTheme.lightTheme,

      // Ruta inicial
      initialRoute: '/login',

      // Rutas de la aplicación
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminScreen(),
        '/users': (context) => const UsersScreen(),
        '/activity': (context) => const ActivityScreen(),
        '/security': (context) => const SecurityScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}