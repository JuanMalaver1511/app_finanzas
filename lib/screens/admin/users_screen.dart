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
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _kyboBg = Color(0xFFF6F7FB);
  static const Color _kyboCard = Colors.white;
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF4F46E5);

  static const int _inactiveThresholdDays = 8;

  String search = "";
  String selectedFilter = "Todos";

  final List<String> filters = const [
    "Todos",
    "Activos",
    "Inactivos",
    "Bloqueados",
    "Nunca ingresaron",
    "Admins",
  ];

  void _refresh() {
    setState(() {});
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 34,
                      color: _danger,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Eliminar usuario",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _kyboPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Esta acción no se puede deshacer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kyboPrimary,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _danger,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Eliminar"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await _confirmDelete();
    if (!confirm) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Usuario eliminado correctamente"),
      ),
    );
  }

  bool _isBlocked(Map<String, dynamic> data) {
    return data['isBlocked'] == true || data['isActive'] == false;
  }

  bool _hasNeverLoggedIn(Map<String, dynamic> data) {
    final lastLogin = data['lastLogin'] as Timestamp?;
    return lastLogin == null;
  }

  int? _inactiveDays(Map<String, dynamic> data) {
    final Timestamp? lastLogin = data['lastLogin'] as Timestamp?;
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;

    final DateTime? reference = lastLogin?.toDate() ?? createdAt?.toDate();
    if (reference == null) return null;

    return DateTime.now().difference(reference).inDays;
  }

  String _statusLabel(Map<String, dynamic> data) {
    if (_isBlocked(data)) return "Bloqueado";

    final lastLogin = data['lastLogin'] as Timestamp?;
    if (lastLogin == null) return "Nunca ingresó";

    final inactiveDays = _inactiveDays(data) ?? 0;
    if (inactiveDays > _inactiveThresholdDays) return "Inactivo";

    return "Activo";
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Activo":
        return _success;
      case "Inactivo":
        return _warning;
      case "Bloqueado":
        return _danger;
      case "Nunca ingresó":
        return _info;
      default:
        return Colors.grey;
    }
  }

  String _statusSubtitle(Map<String, dynamic> data) {
    final status = _statusLabel(data);
    final days = _inactiveDays(data);

    switch (status) {
      case "Activo":
        if (days == null) return "Actividad reciente";
        return days == 0 ? "Ingresó hoy" : "Hace $days día(s)";
      case "Inactivo":
        return days == null
            ? "Sin actividad reciente"
            : "$days días sin ingresar";
      case "Bloqueado":
        return "Acceso restringido";
      case "Nunca ingresó":
        return "Pendiente de primer acceso";
      default:
        return "Sin información";
    }
  }

  String _formatDateShort(Timestamp? timestamp) {
    if (timestamp == null) return "No disponible";

    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String _formatLastAccess(Map<String, dynamic> data) {
    final Timestamp? lastLogin = data['lastLogin'] as Timestamp?;
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;

    if (lastLogin != null) {
      return _formatDateShort(lastLogin);
    }

    if (createdAt != null) {
      return "Sin acceso · ${_formatDateShort(createdAt)}";
    }

    return "No disponible";
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final status = _statusLabel(data);
    final role = (data['role'] ?? 'user').toString().toLowerCase();

    switch (selectedFilter) {
      case "Activos":
        return status == "Activo";
      case "Inactivos":
        return status == "Inactivo";
      case "Bloqueados":
        return status == "Bloqueado";
      case "Nunca ingresaron":
        return status == "Nunca ingresó";
      case "Admins":
        return role == 'admin';
      default:
        return true;
    }
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int total = docs.length;
    int active = 0;
    int inactive = 0;
    int blocked = 0;
    int never = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = _statusLabel(data);

      if (status == "Activo") active++;
      if (status == "Inactivo") inactive++;
      if (status == "Bloqueado") blocked++;
      if (status == "Nunca ingresó") never++;
    }

    return {
      "total": total,
      "active": active,
      "inactive": inactive,
      "blocked": blocked,
      "never": never,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final isTablet = size.width >= 700 && size.width < 1100;

    return Scaffold(
      backgroundColor: _kyboBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, isMobile),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final stats = _calculateStats(docs);

                  final filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name =
                        (data['name'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    final role =
                        (data['role'] ?? '').toString().toLowerCase();

                    final matchesSearch = name.contains(search) ||
                        email.contains(search) ||
                        role.contains(search);

                    final matchesFilter = _matchesFilter(data);

                    return matchesSearch && matchesFilter;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    color: _kyboPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 22,
                        10,
                        isMobile ? 16 : 22,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroSummary(stats, isMobile),
                          const SizedBox(height: 18),
                          _searchBox(),
                          const SizedBox(height: 14),
                          _filtersBar(),
                          const SizedBox(height: 18),
                          _statsGrid(stats, isMobile, isTablet),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            title: "Listado de usuarios",
                            subtitle:
                                "${filtered.length} resultado(s) según búsqueda y filtro actual",
                          ),
                          const SizedBox(height: 12),
                          if (filtered.isEmpty)
                            _emptyState()
                          else
                            isMobile
                                ? Column(
                                    children: filtered
                                        .map((doc) => _userCard(doc))
                                        .toList(),
                                  )
                                : Column(
                                    children: filtered
                                        .map((doc) => _userCard(doc))
                                        .toList(),
                                  ),
                        ],
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

  Widget _header(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 22, 14, isMobile ? 16 : 22, 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _kyboCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
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
                  "Usuarios",
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: _kyboPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Gestiona usuarios, estados y actividad de acceso",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
            icon: const Icon(Icons.add_rounded),
            label: const Text("Crear"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kyboAccent,
              foregroundColor: _kyboPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSummary(Map<String, int> stats, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B2257),
            Color(0xFF3B2F79),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _kyboPrimary.withOpacity(.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroTexts(stats),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _heroChip("Activos", "${stats["active"]}", _success),
                    _heroChip("Inactivos", "${stats["inactive"]}", _warning),
                    _heroChip("Bloqueados", "${stats["blocked"]}", _danger),
                    _heroChip("Nunca ingresaron", "${stats["never"]}", _info),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 4, child: _heroTexts(stats)),
                const SizedBox(width: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _heroChip("Activos", "${stats["active"]}", _success),
                    _heroChip("Inactivos", "${stats["inactive"]}", _warning),
                    _heroChip("Bloqueados", "${stats["blocked"]}", _danger),
                    _heroChip("Nunca ingresaron", "${stats["never"]}", _info),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroTexts(Map<String, int> stats) {
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
          "${stats["total"]} usuarios registrados",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Los inactivos son usuarios con más de $_inactiveThresholdDays días sin ingresar. Aquí puedes identificarlos y tomar acción.",
          style: TextStyle(
            color: Colors.white.withOpacity(.84),
            fontSize: 13,
            height: 1.4,
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

  Widget _searchBox() {
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
          hintText: "Buscar por nombre, correo o rol...",
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

  Widget _filtersBar() {
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _kyboPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? _kyboPrimary
                        : const Color(0xFFE7E9F1),
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

  Widget _statsGrid(Map<String, int> stats, bool isMobile, bool isTablet) {
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
          subtitle: "Base general registrada",
          color: _info,
          icon: Icons.groups_rounded,
        ),
        _statCard(
          title: "Usuarios activos",
          value: "${stats["active"]}",
          subtitle: "Con acceso reciente",
          color: _success,
          icon: Icons.check_circle_rounded,
        ),
        _statCard(
          title: "Usuarios inactivos",
          value: "${stats["inactive"]}",
          subtitle: "Más de $_inactiveThresholdDays días sin entrar",
          color: _warning,
          icon: Icons.schedule_rounded,
        ),
        _statCard(
          title: "Usuarios bloqueados",
          value: "${stats["blocked"]}",
          subtitle: "Acceso restringido",
          color: _danger,
          icon: Icons.block_rounded,
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

  Widget _userCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final name = (data['name'] ?? 'Sin nombre').toString();
    final email = (data['email'] ?? '').toString();
    final role = (data['role'] ?? 'user').toString();
    final status = _statusLabel(data);
    final statusColor = _statusColor(status);
    final statusSubtitle = _statusSubtitle(data);
    final lastAccess = _formatLastAccess(data);
    final daysInactive = _inactiveDays(data);

    final initials = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirm = await _confirmDelete();
        if (confirm) {
          await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Usuario eliminado correctamente")),
            );
          }
        }
        return confirm;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: _danger,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
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
                initials,
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
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: _kyboPrimary,
                        ),
                      ),
                      _smallBadge(
                        role.toUpperCase(),
                        role.toLowerCase() == 'admin'
                            ? _danger.withOpacity(.10)
                            : Colors.grey.shade200,
                        role.toLowerCase() == 'admin'
                            ? _danger
                            : Colors.black54,
                      ),
                      _smallBadge(
                        status,
                        statusColor.withOpacity(.10),
                        statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (email.isNotEmpty)
                    Text(
                      email,
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
                        Icons.calendar_month_rounded,
                        "Último acceso",
                        lastAccess,
                      ),
                      _metaItem(
                        Icons.timelapse_rounded,
                        "Actividad",
                        statusSubtitle,
                      ),
                      if (daysInactive != null)
                        _metaItem(
                          Icons.hourglass_bottom_rounded,
                          "Días",
                          "$daysInactive",
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: "Ver detalle",
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: _kyboPrimary,
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetailScreen(userId: doc.id),
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
          Icon(Icons.search_off_rounded, size: 42, color: Colors.grey.shade500),
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