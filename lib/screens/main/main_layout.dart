import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../dashboard/dashboard_screen.dart';
import '../movements/movements_screen.dart';
import '../debts/deudas_screen.dart';
import '../goals/goals_screen.dart';
import '../profile/profile_screen.dart';
import '../budgets/budgets_screen.dart';
import '../reports/reports_screen.dart';

import '../../widgets/common/app_sidebar.dart';
import '../../widgets/dashboard/add_transaction_dialog.dart';
import '../../services/transaction_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // ─────────────────────────────────────────────
  // ÍNDICES FIJOS DE NAVEGACIÓN
  // ─────────────────────────────────────────────
  static const int pageDashboard = 0;
  static const int pageMovements = 1;
  static const int pageBudgets = 2;
  static const int pageReports = 3;
  static const int pageGoals = 4;
  static const int pageDebts = 5;
  static const int pageProfile = 6;

  int _index = pageDashboard;
  bool _quickMenuOpen = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      DashboardScreen(onChange: _onChange), // 0
      const MovementsScreen(), // 1
      const BudgetsScreen(), // 2
      ReportsScreen(onBack: () => _onChange(pageDashboard)), // 3
      GoalsScreen(onBack: () => _onChange(pageDashboard)), // 4
      const DeudasScreen(), // 5
      ProfileScreen(onBack: () => _onChange(pageDashboard)), // 6
    ];
  }

  void _onChange(int i) {
    if (i < 0 || i >= _screens.length) return;

    setState(() {
      _index = i;
      _quickMenuOpen = false;
    });
  }

  void _toggleQuickMenu() {
    setState(() => _quickMenuOpen = !_quickMenuOpen);
  }

  void _closeQuickMenu() {
    if (_quickMenuOpen) {
      setState(() => _quickMenuOpen = false);
    }
  }

  void _openAddTransactionDialog() {
    _closeQuickMenu();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final txService = TransactionService(user.uid);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => AddTransactionDialog(
        onAdd: (tx) => txService.add(tx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Row(
            children: [
              if (!isMobile)
                AppSidebar(
                  selectedIndex: _index,
                  onChange: _onChange,
                ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: _screens,
                ),
              ),
            ],
          ),

          // Fondo blur cuando se abre el menú rápido.
          if (isMobile && _quickMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeQuickMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    color: Colors.black.withOpacity(0.14),
                  ),
                ),
              ),
            ),

          // Acciones rápidas móviles.
          if (isMobile)
            _QuickActionsOverlay(
              isOpen: _quickMenuOpen,
              onNewTransaction: _openAddTransactionDialog,
              onGoals: () => _onChange(pageGoals),
              onDebts: () => _onChange(pageDebts),
              onProfile: () => _onChange(pageProfile),
            ),
        ],
      ),
      floatingActionButton: isMobile
          ? _KyboFab(
              isOpen: _quickMenuOpen,
              onTap: _toggleQuickMenu,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isMobile
          ? Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                _mobileBottomBar(),
                if (_index == pageDashboard)
                  Positioned(
                    top: -28,
                    child: _CenterAddButton(
                      onTap: _openAddTransactionDialog,
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _mobileBottomBar() {
    return ClipPath(
      clipper: _BottomNavNotchClipper(
        showNotch: _index == pageDashboard,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Row(
              children: [
                _buildNavItem(
                  index: pageDashboard,
                  icon: Icons.grid_view_rounded,
                  label: 'Inicio',
                ),
                _buildNavItem(
                  index: pageMovements,
                  icon: Icons.sync_alt_rounded,
                  label: 'Mov.',
                ),
                if (_index == pageDashboard) const SizedBox(width: 70),
                _buildNavItem(
                  index: pageBudgets,
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Pres.',
                ),
                _buildNavItem(
                  index: pageReports,
                  icon: Icons.analytics_outlined,
                  label: 'Reportes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _index == index;

    const activeColor = Color(0xFF6366F1);
    const inactiveColor = Color(0xFF8E8E93);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onChange(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color:
                isActive ? activeColor.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: isActive ? 1.08 : 1,
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.6,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
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

class _BottomNavNotchClipper extends CustomClipper<Path> {
  final bool showNotch;

  const _BottomNavNotchClipper({
    required this.showNotch,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (!showNotch) {
      return path..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final centerX = size.width / 2;
    const notchRadius = 38.0;
    const notchDepth = 28.0;

    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius, 0);

    path.cubicTo(
      centerX - 28,
      0,
      centerX - 26,
      notchDepth,
      centerX,
      notchDepth,
    );

    path.cubicTo(
      centerX + 26,
      notchDepth,
      centerX + 28,
      0,
      centerX + notchRadius,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _BottomNavNotchClipper oldClipper) {
    return oldClipper.showNotch != showNotch;
  }
}

class _KyboFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _KyboFab({
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: isOpen ? 56 : 58,
            height: isOpen ? 56 : 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFC766),
                  Color(0xFFFFA928),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.85),
                width: 1.1,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0.85, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: Icon(
                isOpen ? Icons.close_rounded : Icons.savings_rounded,
                key: ValueKey(isOpen),
                color: const Color(0xFF2B2257),
                size: isOpen ? 28 : 29,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsOverlay extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onNewTransaction;
  final VoidCallback onGoals;
  final VoidCallback onDebts;
  final VoidCallback onProfile;

  const _QuickActionsOverlay({
    required this.isOpen,
    required this.onNewTransaction,
    required this.onGoals,
    required this.onDebts,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final actions = [
      _QuickActionData(
        label: 'Nueva transacción',
        icon: Icons.add_card_rounded,
        color: const Color(0xFFFFB84E),
        onTap: onNewTransaction,
      ),
      _QuickActionData(
        label: 'Metas',
        icon: Icons.flag_rounded,
        color: const Color(0xFF6366F1),
        onTap: onGoals,
      ),
      _QuickActionData(
        label: 'Deudas',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFFE74C3C),
        onTap: onDebts,
      ),
      _QuickActionData(
        label: 'Perfil',
        icon: Icons.person_outline_rounded,
        color: const Color(0xFF2B2257),
        onTap: onProfile,
      ),
    ];

    return Positioned(
      right: 18,
      bottom: 100 + bottomPadding,
      child: IgnorePointer(
        ignoring: !isOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(actions.length, (index) {
            final action = actions[index];

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: isOpen ? 1 : 0,
              ),
              duration: Duration(milliseconds: 170 + (index * 35)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final safeValue = value.clamp(0.0, 1.0);

                return Opacity(
                  opacity: safeValue,
                  child: Transform.translate(
                    offset: Offset(0, (1 - safeValue) * 18),
                    child: Transform.scale(
                      scale: 0.86 + (safeValue * 0.14),
                      child: child,
                    ),
                  ),
                );
              },
              child: _QuickActionButton(
                label: action.label,
                icon: action.icon,
                color: action.color,
                onTap: action.onTap,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFEAECEF),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: color,
            borderRadius: BorderRadius.circular(18),
            elevation: 7,
            shadowColor: color.withOpacity(0.35),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterAddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CenterAddButton({
    required this.onTap,
  });

  @override
  State<_CenterAddButton> createState() => _CenterAddButtonState();
}

class _CenterAddButtonState extends State<_CenterAddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.92 : 1,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.86, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
