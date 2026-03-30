import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../movements/movements_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/common/app_sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  void _onChange(int i) {
    setState(() => _index = i);
  }

  List<Widget> get _screens => [
        const DashboardScreen(),
        const MovementsScreen(),
        const Center(child: Text("Metas próximamente")),
        const Center(child: Text("Deudas próximamente")),
        ProfileScreen(onBack: () => _onChange(0)),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (desktop)
          if (MediaQuery.of(context).size.width > 800)
            AppSidebar(
              selectedIndex: _index,
              onChange: _onChange,
            ),

          // CONTENIDO
          Expanded(child: _screens[_index]),
        ],
      ),

      // Bottom nav (móvil)
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? BottomNavigationBar(
              currentIndex: _index,
              onTap: _onChange,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard), label: "Inicio"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.swap_horiz), label: "Mov."),
                BottomNavigationBarItem(icon: Icon(Icons.flag), label: "Metas"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.credit_card), label: "Deudas"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: "Perfil"),
              ],
            )
          : null,
    );
  }
}
