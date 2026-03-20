import 'package:flutter/material.dart';
import 'package:app_finanzas/screens/admin/users_screen.dart';
import 'package:app_finanzas/screens/admin/activity_screen.dart';
import 'package:app_finanzas/screens/admin/security_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrativo"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _card(
              title: "Usuarios",
              icon: Icons.people,
              onTap: () => _goTo(context, const UsersScreen()),
            ),
            _card(
              title: "Actividad",
              icon: Icons.timeline,
              onTap: () => _goTo(context, const ActivityScreen()),
            ),
            _card(
              title: "Seguridad",
              icon: Icons.security,
              onTap: () => _goTo(context, const SecurityScreen()),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 MÉTODO REUTILIZABLE (MEJOR PRÁCTICA)
  void _goTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}