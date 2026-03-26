import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 🔥 IMPORTANTE
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

import 'screens/auth/auth_wrapper.dart';

// Pantallas
import 'screens/login/login_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/activity_screen.dart';
import 'screens/admin/security_screen.dart';
import 'screens/profile/profile_screen.dart';

Future<void> main() async {
  //await dotenv.load(fileName: ".env");
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
      theme: AppTheme.lightTheme,

      // 🔥 SOLUCIÓN AL ERROR
      locale: const Locale('es'),

      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      /// CONTROL GLOBAL DE SESIÓN
      home: const AuthWrapper(),

      /// RUTAS PROTEGIDAS
      routes: {
        '/login': (context) {
          final user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            return const AdminScreen();
          }

          return const LoginScreen();
        },
        '/admin': (context) {
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            return const LoginScreen();
          }

          return const AdminScreen();
        },
        '/users': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          return const UsersScreen();
        },
        '/activity': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          return const ActivityScreen();
        },
        '/security': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          return const SecurityScreen();
        },
        '/profile': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          return const ProfileScreen();
        },
      },
    );
  }
}
