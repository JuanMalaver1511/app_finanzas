import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🔥 Inicializar functions correctamente
    FirebaseFunctions.instanceFor(region: 'us-central1');

    // 🔥 CONFIG EXTRA PARA WEB (ESTABILIDAD)
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }

  } catch (e) {
    debugPrint("🔥 Error inicializando Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// FUNCIÓN PARA OBTENER ROL
  Future<String?> _getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return doc.data()?['role'];
    } catch (e) {
      debugPrint("🔥 Error obteniendo rol: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

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

      /// 🔥 CONTROL GLOBAL DE SESIÓN
      home: const AuthWrapper(),

      /// 🔥 RUTAS
      routes: {
        '/login': (context) {
          final user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            return const AuthWrapper();
          }

          return const LoginScreen();
        },

        '/admin': (context) {
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) return const LoginScreen();

          return FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data != 'admin') {
                return const AuthWrapper();
              }

              return const AdminScreen();
            },
          );
        },

        '/users': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();

          return FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data != 'admin') {
                return const AuthWrapper();
              }

              return const UsersScreen();
            },
          );
        },

        '/activity': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();

          return FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data != 'admin') {
                return const AuthWrapper();
              }

              return const ActivityScreen();
            },
          );
        },

        '/security': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();

          return FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data != 'admin') {
                return const AuthWrapper();
              }

              return const SecurityScreen();
            },
          );
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