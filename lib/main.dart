import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // 🔥 NUEVO
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/push_notification_service.dart';

import 'screens/auth/auth_wrapper.dart';

// Pantallas
import 'screens/login/login_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/activity_screen.dart';
import 'screens/admin/security_screen.dart';
import 'screens/admin/notifications_admin_screen.dart';
import 'screens/profile/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔥 CARGAR ENV
    await dotenv.load(fileName: ".env");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFunctions.instanceFor(region: 'us-central1');
    await PushNotificationService.instance.initialize();

    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
  } catch (e) {
    debugPrint("🔥 Error inicializando: $e");
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

  Widget _adminGuard(Widget screen) {
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

        return screen;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 SOLUCIÓN AL VERDE FOSFORESCENTE
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2B2257),
        statusBarIconBrightness: Brightness.light,
      ),
    );

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

        '/admin': (context) => _adminGuard(const AdminScreen()),

        '/users': (context) => _adminGuard(const UsersScreen()),

        '/activity': (context) => _adminGuard(const ActivityScreen()),

        '/security': (context) => _adminGuard(const SecurityScreen()),

        '/notifications': (context) =>
            _adminGuard(const NotificationsAdminScreen()),

        '/profile': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          return const ProfileScreen();
        },
      },
    );
  }
}