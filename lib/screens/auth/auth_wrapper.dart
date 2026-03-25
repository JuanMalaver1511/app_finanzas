import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login/login_screen.dart';
import '../admin/admin_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // NO LOGUEADO → LOGIN
        if (user == null) {
          return const LoginScreen();
        }

        // LOGUEADO → ADMIN (o dashboard)
        return const AdminScreen();
      },
    );
  }
}