import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final FirestoreService _firestore = FirestoreService();

  List<AppUser> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await _firestore.getAllUsers();

    setState(() {
      users = data;
      isLoading = false;
    });
  }

  /// 🔒 ACTIVAR / DESACTIVAR USUARIO
  Future<void> toggleUser(String uid, bool current) async {
    await _firestore.updateUserStatus(uid, !current);
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seguridad")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (_, i) {
                final user = users[i];

                return Card(
                  child: ListTile(
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        Text("Intentos fallidos: ${user.failedAttempts}"),
                        Text("Estado: ${user.isActive ? "Activo" : "Bloqueado"}"),
                      ],
                    ),
                    trailing: Switch(
                      value: user.isActive,
                      onChanged: (_) => toggleUser(user.uid, user.isActive),
                    ),
                  ),
                );
              },
            ),
    );
  }
}