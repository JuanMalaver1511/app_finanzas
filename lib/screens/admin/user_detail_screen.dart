import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_edit_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  /// ==============================
  /// FORMATO INSTAGRAM
  /// ==============================
  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "No disponible";

    final date = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return "Hace unos segundos";
    } else if (difference.inMinutes < 60) {
      return "Hace ${difference.inMinutes} min";
    } else if (difference.inHours < 24) {
      return "Hace ${difference.inHours} h";
    } else if (difference.inDays < 7) {
      return "Hace ${difference.inDays} días";
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;

      return "$day/$month/$year";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            _header(context),

            /// CONTENIDO
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data =
                      snapshot.data!.data() as Map<String, dynamic>;

                  final name = data['name'] ?? 'Sin nombre';
                  final email = data['email'] ?? '';
                  final role = data['role'] ?? 'user';
                  final isActive = data['isActive'] ?? true;

                  final createdAt = data['createdAt'];
                  final lastLogin = data['lastLogin'];

                  return Center(
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Column(
                          children: [

                            /// AVATAR
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.orange.shade200,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// NOMBRE
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// EMAIL
                            Text(
                              email,
                              style: const TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 20),

                            /// INFO
                            _info("UID", userId),
                            _info("Rol", role),
                            _info(
                              "Estado",
                              isActive ? "Activo" : "Bloqueado",
                            ),

                            /// FECHAS PRO
                            _info(
                              "Cuenta creada",
                              _formatTimeAgo(createdAt),
                            ),

                            _info(
                              "Último acceso",
                              _formatTimeAgo(lastLogin),
                            ),

                            const SizedBox(height: 20),

                            /// BOTÓN EDITAR
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          UserEditScreen(userId: userId),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB84E),
                                ),
                                child: const Text("Editar usuario"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HEADER
  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [

          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),

          const SizedBox(width: 10),

          const Text(
            "Detalle usuario",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ITEM INFO
  Widget _info(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text("$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}