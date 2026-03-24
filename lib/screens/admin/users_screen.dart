import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail_screen.dart';
import 'user_create_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String search = "";

  void _refresh() {
    setState(() {});
  }

  /// MODAL CONFIRMAR ELIMINACIÓN
  Future<bool> _confirmDelete() async {
    return await showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Icon(Icons.warning_amber_rounded,
                      size: 50, color: Colors.red),

                  const SizedBox(height: 15),

                  const Text(
                    "Eliminar usuario",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Esta acción no se puede deshacer",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Eliminar"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  /// ELIMINAR
  Future<void> _deleteUser(String userId) async {
    final confirm = await _confirmDelete();

    if (!confirm) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Column(
          children: [

            _header(context),

            /// BUSCADOR
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() => search = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: "Buscar usuario...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            /// LISTA
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),

                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final name = (data['name'] ?? '').toLowerCase();
                    final email = (data['email'] ?? '').toLowerCase();

                    return name.contains(search) || email.contains(search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("Sin resultados"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {

                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final name = data['name'] ?? 'Sin nombre';
                      final email = data['email'] ?? '';
                      final role = data['role'] ?? 'user';
                      final isActive = data['isActive'] ?? true;

                      /// SWIPE DELETE
                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(),
                        onDismissed: (_) => _deleteUser(doc.id),

                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),

                          child: Row(
                            children: [

                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.orange.shade200,
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'U',
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: role == 'admin'
                                                ? Colors.red.shade100
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            role.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: role == 'admin'
                                                  ? Colors.red
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      email,
                                      style: const TextStyle(color: Colors.grey),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      isActive ? "Activo" : "Bloqueado",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserDetailScreen(
                                        userId: doc.id,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    _refresh();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 10),
              const Text(
                "Usuarios",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserCreateScreen(),
                ),
              );

              if (result == true) {
                _refresh();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Crear"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB84E),
            ),
          ),
        ],
      ),
    );
  }
}