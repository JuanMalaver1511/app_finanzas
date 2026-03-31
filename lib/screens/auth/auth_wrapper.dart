import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main/main_layout.dart';

import '../login/login_screen.dart';
import '../admin/admin_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        /// LOADING AUTH
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        /// ❌ NO LOGUEADO
        if (user == null) {
          return const LoginScreen();
        }

        /// LOGUEADO → CONSULTAR FIRESTORE
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            
            /// LOADING FIRESTORE
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            /// ERROR FIRESTORE
            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Error cargando usuario')),
              );
            }

            /// DOCUMENTO NO EXISTE
            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>;

            /// USUARIO INACTIVO
            if (data['isActive'] == false) {
              Future.microtask(() {
                FirebaseAuth.instance.signOut();
              });

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = data['role'] ?? 'user';

            /// CONTROL DE ROLES
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