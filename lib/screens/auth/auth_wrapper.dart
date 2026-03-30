import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main/main_layout.dart';

import '../login/login_screen.dart';
import '../admin/admin_screen.dart';
import '../dashboard/dashboard_screen.dart';

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

        // LOGUEADO → consultar rol en Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = roleSnapshot.data?.data() as Map<String, dynamic>?;

            if (data == null || data['isActive'] == false) {
              Future.microtask(() {
                FirebaseAuth.instance.signOut();
              });

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = data['role'] ?? 'user';

            if (role == 'admin') {
              return const AdminScreen();
            } else {
              return const MainLayout();
            }
          },
        );
      },
    );
  }
}
