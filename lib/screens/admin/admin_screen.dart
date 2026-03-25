import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin/sidebar_icon.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int totalUsers = 0;
  int activeUsers = 0;
  int blockedUsers = 0;

  bool isLoading = true;

  double activePercent = 0;
  double blockedPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    int total = snapshot.docs.length;
    int active = 0;
    int blocked = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['isActive'] == true) {
        active++;
      } else {
        blocked++;
      }
    }

    if (!mounted) return;

    setState(() {
      totalUsers = total;
      activeUsers = active;
      blockedUsers = blocked;

      /// CALCULAR PORCENTAJES
      activePercent = total == 0 ? 0 : (active / total) * 100;
      blockedPercent = total == 0 ? 0 : (blocked / total) * 100;

      isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Cerrar sesión"),
          content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB84E),
              ),
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );

    // Si cancela → no hace nada
    if (confirm != true) return;

    // Cierra sesión
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Admin';

    return Scaffold(
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          /// SIDEBAR
          if (!isMobile)
            Container(
              width: 80,
              color: const Color(0xFFFFB84E),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 30),
                      const SizedBox(height: 30),
                      SidebarIcon(icon: Icons.dashboard, onTap: () {}),
                      SidebarIcon(
                        icon: Icons.people,
                        onTap: () {
                          Navigator.pushNamed(context, '/users');
                        },
                      ),
                      SidebarIcon(
                        icon: Icons.bar_chart,
                        onTap: () {
                          Navigator.pushNamed(context, '/activity');
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SidebarIcon(
                      icon: Icons.logout,
                      onTap: () => _logout(context),
                    ),
                  )
                ],
              ),
            ),

          /// CONTENIDO
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: SafeArea(
                child: Column(
                  children: [
                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (isMobile)
                                Builder(
                                  builder: (context) => IconButton(
                                    icon: const Icon(Icons.menu),
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                  ),
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Panel Administrativo",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.notifications_none),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/profile');
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.orange.shade200,
                                    child: Text(
                                      userName[0].toUpperCase(),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),

                    /// BODY
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : Wrap(
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: [
                                      /// USUARIOS
                                      _HoverCard(
                                        icon: Icons.people,
                                        title: "Usuarios",
                                        value: "$totalUsers",
                                        subtitle:
                                            "Activos: $activeUsers (${activePercent.toStringAsFixed(1)}%)\n"
                                            "Bloqueados: $blockedUsers (${blockedPercent.toStringAsFixed(1)}%)",
                                        color: Colors.blue,
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/users');
                                        },
                                      ),

                                      /// ACTIVIDAD
                                      _HoverCard(
                                        icon: Icons.bar_chart,
                                        title: "Actividad",
                                        value:
                                            "${activePercent.toStringAsFixed(0)}%",
                                        subtitle: "Usuarios activos del total",
                                        color: Colors.orange,
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/activity');
                                        },
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// DRAWER
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(child: Text("Menú")),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Usuarios"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Estadísticas"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/activity');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

/// CARD 
class _HoverCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HoverCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          height: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHover ? 0.15 : 0.05),
                blurRadius: isHover ? 15 : 8,
              )
            ],
          ),
          transform: Matrix4.identity()..scale(isHover ? 1.03 : 1.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(color: Colors.grey)),
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Text(
                      "Ver detalles →",
                      style: TextStyle(color: Colors.blue),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
