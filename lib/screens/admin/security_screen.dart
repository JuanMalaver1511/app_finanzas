import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboPrimarySoft = Color(0xFF3B2F79);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _kyboBg = Color(0xFFF6F7FB);
  static const Color _kyboCard = Colors.white;
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF4F46E5);

  final FirestoreService _firestore = FirestoreService();

  List<AppUser> users = [];
  bool isLoading = true;
  bool isUpdating = false;
  String search = "";
  String selectedFilter = "Todos";

  final List<String> filters = const [
    "Todos",
    "Activos",
    "Bloqueados",
    "Con intentos fallidos",
  ];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);

    final data = await _firestore.getAllUsers();

    if (!mounted) return;

    setState(() {
      users = data;
      isLoading = false;
    });
  }

  Future<void> toggleUser(String uid, bool current) async {
    setState(() => isUpdating = true);

    try {
      await _firestore.updateUserStatus(uid, !current);
      await loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            current
                ? "Usuario bloqueado correctamente"
                : "Usuario activado correctamente",
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo actualizar el estado del usuario"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  Map<String, int> _calculateStats(List<AppUser> allUsers) {
    final total = allUsers.length;
    final active = allUsers.where((u) => u.isActive).length;
    final blocked = allUsers.where((u) => !u.isActive).length;
    final withAttempts = allUsers.where((u) => u.failedAttempts > 0).length;

    return {
      "total": total,
      "active": active,
      "blocked": blocked,
      "attempts": withAttempts,
    };
  }

  List<AppUser> _filteredUsers() {
    return users.where((user) {
      final name = user.name.toLowerCase();
      final email = user.email.toLowerCase();

      final matchesSearch = name.contains(search) || email.contains(search);

      bool matchesFilter = true;

      switch (selectedFilter) {
        case "Activos":
          matchesFilter = user.isActive;
          break;
        case "Bloqueados":
          matchesFilter = !user.isActive;
          break;
        case "Con intentos fallidos":
          matchesFilter = user.failedAttempts > 0;
          break;
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Color _statusColor(AppUser user) {
    if (!user.isActive) return _danger;
    if (user.failedAttempts > 0) return _warning;
    return _success;
  }

  String _statusText(AppUser user) {
    if (!user.isActive) return "Bloqueado";
    if (user.failedAttempts > 0) return "Activo con alertas";
    return "Activo";
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    final stats = _calculateStats(users);
    final filteredUsers = _filteredUsers();

    return Scaffold(
      backgroundColor: _kyboBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadUsers,
          color: _kyboPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 16 : 20,
              isMobile ? 16 : 24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context, isMobile),
                const SizedBox(height: 18),
                _buildHeroBanner(stats, isMobile),
                const SizedBox(height: 18),
                _buildSearchBox(),
                const SizedBox(height: 14),
                _buildFiltersBar(),
                const SizedBox(height: 18),
                _buildStatsGrid(stats, isMobile, isTablet),
                const SizedBox(height: 18),
                _sectionTitle(
                  title: "Control de acceso",
                  subtitle:
                      "${filteredUsers.length} usuario(s) según búsqueda y filtro actual",
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredUsers.isEmpty)
                  _emptyState()
                else
                  Column(
                    children: filteredUsers
                        .map((user) => _userCard(user, isUpdating))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
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
          Container(
            decoration: BoxDecoration(
              color: _kyboPrimary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: _kyboPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Seguridad",
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: _kyboPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Supervisa accesos, bloqueos e intentos fallidos",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(Map<String, int> stats, bool isMobile) {
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
                _heroTextBlock(stats),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _heroChip("Activos", "${stats["active"]}", _success),
                    _heroChip("Bloqueados", "${stats["blocked"]}", _danger),
                    _heroChip(
                      "Con alertas",
                      "${stats["attempts"]}",
                      _warning,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 4, child: _heroTextBlock(stats)),
                const SizedBox(width: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _heroChip("Activos", "${stats["active"]}", _success),
                    _heroChip("Bloqueados", "${stats["blocked"]}", _danger),
                    _heroChip(
                      "Con alertas",
                      "${stats["attempts"]}",
                      _warning,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroTextBlock(Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kybo Security",
          style: TextStyle(
            color: Color(0xFFFFD89A),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${stats["total"]} usuarios bajo monitoreo",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Aquí puedes identificar accesos bloqueados y usuarios con intentos fallidos para actuar rápido.",
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

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => search = value.toLowerCase().trim());
        },
        decoration: InputDecoration(
          hintText: "Buscar por nombre o correo...",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search_rounded, color: _kyboPrimary),
          suffixIcon: search.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() => search = "");
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                setState(() => selectedFilter = filter);
              },
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _kyboPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? _kyboPrimary : const Color(0xFFE7E9F1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _kyboPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.6,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid(
    Map<String, int> stats,
    bool isMobile,
    bool isTablet,
  ) {
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
          value: "${stats["total"]}",
          subtitle: "Base monitoreada",
          color: _info,
          icon: Icons.groups_rounded,
        ),
        _statCard(
          title: "Usuarios activos",
          value: "${stats["active"]}",
          subtitle: "Acceso habilitado",
          color: _success,
          icon: Icons.verified_user_rounded,
        ),
        _statCard(
          title: "Bloqueados",
          value: "${stats["blocked"]}",
          subtitle: "Acceso restringido",
          color: _danger,
          icon: Icons.block_rounded,
        ),
        _statCard(
          title: "Con alertas",
          value: "${stats["attempts"]}",
          subtitle: "Intentos fallidos > 0",
          color: _warning,
          icon: Icons.warning_amber_rounded,
        ),
      ],
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

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kyboPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12.8,
          ),
        ),
      ],
    );
  }

  Widget _userCard(AppUser user, bool disabled) {
    final statusColor = _statusColor(user);
    final statusText = _statusText(user);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _kyboAccent.withOpacity(.22),
            child: Text(
              user.name.trim().isNotEmpty
                  ? user.name.trim()[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: _kyboPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: _kyboPrimary,
                      ),
                    ),
                    _smallBadge(
                      statusText,
                      statusColor.withOpacity(.10),
                      statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _metaItem(
                      Icons.lock_outline_rounded,
                      "Intentos fallidos",
                      "${user.failedAttempts}",
                    ),
                    _metaItem(
                      Icons.verified_user_outlined,
                      "Estado",
                      statusText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: user.isActive,
            activeThumbColor: _success,
            onChanged:
                disabled ? null : (_) => toggleUser(user.uid, user.isActive),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBEEF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _kyboPrimary),
          const SizedBox(width: 7),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
              ),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: _kyboPrimary,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBEEF5)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.security_outlined,
            size: 42,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 12),
          const Text(
            "No hay usuarios para mostrar",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kyboPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Prueba con otra búsqueda o cambia el filtro actual.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
