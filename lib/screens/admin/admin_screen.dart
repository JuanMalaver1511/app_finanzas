import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/admin/sidebar_icon.dart';
import '../auth/auth_wrapper.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboPrimarySoft = Color(0xFF3B2F79);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _kyboBg = Color(0xFFF6F7FB);
  static const Color _kyboCard = Colors.white;
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF4F46E5);

  static const int _inactiveThresholdDays = 8;

  int totalUsers = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;
  int blockedUsers = 0;
  int neverLoggedUsers = 0;

  bool isLoading = true;

  double activePercent = 0;
  double inactivePercent = 0;
  double blockedPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final now = DateTime.now();

    int total = snapshot.docs.length;
    int active = 0;
    int inactive = 0;
    int blocked = 0;
    int neverLogged = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final bool isBlocked =
          data['isBlocked'] == true || data['isActive'] == false;

      final Timestamp? lastLoginTs = data['lastLogin'] as Timestamp?;
      final Timestamp? createdAtTs = data['createdAt'] as Timestamp?;

      final DateTime? lastLogin = lastLoginTs?.toDate();
      final DateTime? createdAt = createdAtTs?.toDate();

      if (isBlocked) {
        blocked++;
        continue;
      }

      if (lastLogin == null) {
        neverLogged++;
      }

      final DateTime? referenceDate = lastLogin ?? createdAt;
      final int inactiveDays =
          referenceDate == null ? 9999 : now.difference(referenceDate).inDays;

      if (lastLogin == null) {
        if (createdAt != null &&
            now.difference(createdAt).inDays <= _inactiveThresholdDays) {
          active++;
        } else {
          inactive++;
        }
      } else if (inactiveDays > _inactiveThresholdDays) {
        inactive++;
      } else {
        active++;
      }
    }

    if (!mounted) return;

    setState(() {
      totalUsers = total;
      activeUsers = active;
      inactiveUsers = inactive;
      blockedUsers = blocked;
      neverLoggedUsers = neverLogged;

      activePercent = total == 0 ? 0 : (active / total) * 100;
      inactivePercent = total == 0 ? 0 : (inactive / total) * 100;
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
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Cerrar sesión"),
          content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kyboAccent,
                foregroundColor: _kyboPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Cerrar sesión"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;
    final isTablet = width >= 760 && width < 1100;

    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? 'Admin';

    return Scaffold(
      backgroundColor: _kyboBg,
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadUserStats,
                color: _kyboPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 16 : 20,
                    isMobile ? 16 : 24,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdminHeader(userName, isMobile, user),
                      const SizedBox(height: 18),
                      _buildHeroBanner(isMobile),
                      const SizedBox(height: 18),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _buildStatsGrid(isMobile, isTablet),
                        const SizedBox(height: 20),
                        _buildMainCards(isMobile, isTablet),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 92,
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kyboPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kyboPrimary.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: _kyboAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 26),
          SidebarIcon(icon: Icons.dashboard_rounded, onTap: () {}),
          SidebarIcon(
            icon: Icons.people_alt_rounded,
            onTap: () => Navigator.pushNamed(context, '/users'),
          ),
          SidebarIcon(
            icon: Icons.bar_chart_rounded,
            onTap: () => Navigator.pushNamed(context, '/activity'),
          ),
          SidebarIcon(
            icon: Icons.notifications_active_rounded,
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(String userName, bool isMobile, User? user) {
    final hour = DateTime.now().hour;

    String saludo;
    if (hour < 12) {
      saludo = "Buenos días";
    } else if (hour < 18) {
      saludo = "Buenas tardes";
    } else {
      saludo = "Buenas noches";
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: _kyboPrimary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: _kyboPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          if (isMobile) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$saludo,",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    color: _kyboPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Resumen general del panel administrativo de Kybo",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'perfil') {
                Navigator.pushNamed(context, '/profile');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'perfil',
                child: Text('Editar perfil'),
              ),
            ],
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _kyboPrimary.withOpacity(.08),
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? Text(
                      userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: _kyboPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kyboPrimary, _kyboPrimarySoft],
        ),
        boxShadow: [
          BoxShadow(
            color: _kyboPrimary.withOpacity(.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroTexts(),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _heroChip("Activos", "${activePercent.toStringAsFixed(1)}%",
                        _success),
                    _heroChip("Inactivos",
                        "${inactivePercent.toStringAsFixed(1)}%", _warning),
                    _heroChip("Bloqueados",
                        "${blockedPercent.toStringAsFixed(1)}%", _danger),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 4, child: _heroTexts()),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _heroChip(
                          "Activos",
                          "${activePercent.toStringAsFixed(1)}%",
                          _success,
                        ),
                        _heroChip(
                          "Inactivos",
                          "${inactivePercent.toStringAsFixed(1)}%",
                          _warning,
                        ),
                        _heroChip(
                          "Bloqueados",
                          "${blockedPercent.toStringAsFixed(1)}%",
                          _danger,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Panel Kybo",
          style: TextStyle(
            color: Color(0xFFFFD89A),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "$totalUsers usuarios registrados en la plataforma",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Los usuarios inactivos son quienes no registran acceso en más de $_inactiveThresholdDays días.",
          style: TextStyle(
            color: Colors.white.withOpacity(.84),
            fontSize: 13.2,
            height: 1.38,
          ),
        ),
      ],
    );
  }

  Widget _heroChip(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              fontWeight: FontWeight.w600,
              fontSize: 12.3,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile, bool isTablet) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isMobile ? 2.8 : (isTablet ? 2.2 : 2.45),
      children: [
        _statCard(
          title: "Total usuarios",
          value: "$totalUsers",
          subtitle: "Base general registrada",
          color: _info,
          icon: Icons.groups_rounded,
        ),
        _statCard(
          title: "Usuarios activos",
          value: "$activeUsers",
          subtitle: "Con acceso reciente",
          color: _success,
          icon: Icons.check_circle_rounded,
        ),
        _statCard(
          title: "Usuarios inactivos",
          value: "$inactiveUsers",
          subtitle: "Más de $_inactiveThresholdDays días sin entrar",
          color: _warning,
          icon: Icons.schedule_rounded,
        ),
        _statCard(
          title: "Bloqueados",
          value: "$blockedUsers",
          subtitle: "Acceso restringido",
          color: _danger,
          icon: Icons.block_rounded,
        ),
      ],
    );
  }

  Widget _buildMainCards(bool isMobile, bool isTablet) {
    final cards = [
      _DashboardCardData(
        icon: Icons.people_alt_rounded,
        title: "Usuarios",
        value: "$totalUsers",
        subtitle:
            "Activos: $activeUsers · Inactivos: $inactiveUsers · Bloqueados: $blockedUsers",
        color: _info,
        cta: "Gestionar usuarios",
        onTap: () => Navigator.pushNamed(context, '/users'),
      ),
      _DashboardCardData(
        icon: Icons.analytics_rounded,
        title: "Actividad",
        value: "${activePercent.toStringAsFixed(0)}%",
        subtitle: "Usuarios activos sobre el total actual",
        color: _warning,
        cta: "Ver actividad",
        onTap: () => Navigator.pushNamed(context, '/activity'),
      ),
      _DashboardCardData(
        icon: Icons.person_off_rounded,
        title: "Sin primer acceso",
        value: "$neverLoggedUsers",
        subtitle: "Usuarios creados que aún no han ingresado",
        color: _success,
        cta: "Revisar usuarios",
        onTap: () => Navigator.pushNamed(context, '/users'),
      ),
      _DashboardCardData(
        icon: Icons.notifications_active_rounded,
        title: "Centro de mensajes",
        value: "Activo",
        subtitle: "Campañas, historial y automatizaciones configuradas",
        color: const Color(0xFF8B5CF6),
        cta: "Gestionar mensajes",
        onTap: () => Navigator.pushNamed(context, '/notifications'),
      ),
    ];

    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 2),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.6 : 1.75,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _HoverCard(data: card);
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.4,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _kyboPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.2,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.admin_panel_settings_rounded),
              title: Text(
                "Kybo Admin",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded),
              title: const Text("Usuarios"),
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text("Actividad"),
              onTap: () => Navigator.pushNamed(context, '/activity'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_rounded),
              title: const Text("Notificaciones"),
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text("Cerrar sesión"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCardData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final String cta;
  final VoidCallback onTap;

  const _DashboardCardData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.cta,
    required this.onTap,
  });
}

class _HoverCard extends StatefulWidget {
  final _DashboardCardData data;

  const _HoverCard({required this.data});

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
      child: GestureDetector(
        onTap: widget.data.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          transform: Matrix4.identity()..translate(0.0, isHover ? -4.0 : 0.0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.data.color.withOpacity(.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHover ? 0.08 : 0.04),
                blurRadius: isHover ? 18 : 12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.data.color.withOpacity(.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.data.icon, color: widget.data.color),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: widget.data.color,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.data.title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.data.value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B2257),
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.4,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.data.cta,
                style: TextStyle(
                  color: widget.data.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
