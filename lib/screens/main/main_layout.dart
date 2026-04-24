import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../movements/movements_screen.dart';
import '../debts/deudas_screen.dart';
import '../goals/goals_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/common/app_sidebar.dart';
import '../budgets/budgets_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onChange(int i) {
    setState(() => _index = i);
  }

  List<Widget> get _screens => [
        DashboardScreen(onChange: _onChange),
        const MovementsScreen(),
        const BudgetsScreen(),
        GoalsScreen(onBack: () => _onChange(0)),
        const DeudasScreen(),
        ProfileScreen(onBack: () => _onChange(0)),
      ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile)
            AppSidebar(
              selectedIndex: _index,
              onChange: _onChange,
            ),
          Expanded(child: _screens[_index]),
        ],
      ),
      bottomNavigationBar: isMobile
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.10),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.grid_view_rounded,
                        label: 'Inicio',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.sync_alt_rounded,
                        label: 'Mov.',
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.pie_chart_outline_rounded,
                        label: 'Pres.',
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.flag_rounded,
                        label: 'Metas',
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Deudas',
                      ),
                      _buildNavItem(
                        index: 5,
                        icon: Icons.person_outline_rounded,
                        label: 'Perfil',
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _index == index;
    const activeColor = Color(0xFF6C4DFF);
    const inactiveColor = Color(0xFF8E8E93);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onChange(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color:
                isActive ? activeColor.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
