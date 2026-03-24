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

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

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
      isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    final isMobile = size < 700;

    final user = FirebaseAuth.instance.currentUser;

    String userName = user?.displayName ??
        user?.email?.split('@').first ??
        'Admin';

    return Scaffold(
      drawer: isMobile ? _drawer(context) : null,
      body: Row(
        children: [

          /// SIDEBAR DESKTOP
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
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 🔥 HEADER PRO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        /// IZQUIERDA
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
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        /// DERECHA
                        Row(
                          children: [
                            const Icon(Icons.notifications_none),
                            const SizedBox(width: 10),

                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: CircleAvatar(
                                backgroundColor: Colors.orange.shade200,
                                child: Text(userName[0].toUpperCase()),
                              ),
                            )
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 40),

                    /// CARDS
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [

                              /// USUARIOS
                              _card(
                                icon: Icons.people,
                                title: "Usuarios",
                                value: "$totalUsers",
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.pushNamed(context, '/users');
                                },
                              ),

                              /// FUTURO
                              _card(
                                icon: Icons.bar_chart,
                                title: "A futuro",
                                value: "--",
                                color: Colors.orange,
                                onTap: () {},
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// CARD PRO
  Widget _card({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              )
            ],
          ),
          child: Row(
            children: [

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),

              const SizedBox(width: 15),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Ver detalles →",
                    style: TextStyle(color: Colors.blue),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// DRAWER MOBILE
  Widget _drawer(BuildContext context) {
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
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}