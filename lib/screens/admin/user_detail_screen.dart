import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_edit_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

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
      return _formatDate(date);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return "No disponible";
    final date = timestamp.toDate();
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return "${_formatDate(date)} · $hh:$mm";
  }

  bool _isBlocked(Map<String, dynamic> data) {
    return data['isBlocked'] == true || data['isActive'] == false;
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

    final Timestamp? lastLogin = data['lastLogin'] as Timestamp?;
    if (lastLogin == null) return "Nunca ingresó";

    final days = _inactiveDays(data) ?? 0;
    if (days > _inactiveThresholdDays) return "Inactivo";

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
        return days == null ? "Sin actividad reciente" : "$days días sin ingresar";
      case "Bloqueado":
        return "Acceso restringido";
      case "Nunca ingresó":
        return "Pendiente de primer acceso";
      default:
        return "Sin información";
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: _kyboBg,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(
                child: Text("Usuario no encontrado"),
              );
            }

            final name = (data['name'] ?? 'Sin nombre').toString();
            final email = (data['email'] ?? '').toString();
            final role = (data['role'] ?? 'user').toString();

            final createdAt = data['createdAt'] as Timestamp?;
            final lastLogin = data['lastLogin'] as Timestamp?;

            final status = _statusLabel(data);
            final statusColor = _statusColor(status);
            final statusSubtitle = _statusSubtitle(data);
            final daysInactive = _inactiveDays(data);

            final initials = name.trim().isNotEmpty
                ? name.trim().substring(0, 1).toUpperCase()
                : 'U';

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 20,
                isMobile ? 16 : 24,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context, isMobile),
                      const SizedBox(height: 18),
                      _buildHeroBanner(
                        isMobile: isMobile,
                        name: name,
                        email: email,
                        initials: initials,
                        status: status,
                        statusColor: statusColor,
                        statusSubtitle: statusSubtitle,
                        role: role,
                      ),
                      const SizedBox(height: 18),
                      _buildMainCard(
                        context: context,
                        isMobile: isMobile,
                        name: name,
                        email: email,
                        role: role,
                        status: status,
                        statusColor: statusColor,
                        createdAt: createdAt,
                        lastLogin: lastLogin,
                        daysInactive: daysInactive,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
                  "Detalle del usuario",
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: _kyboPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Información completa del acceso y actividad",
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

  Widget _buildHeroBanner({
    required bool isMobile,
    required String name,
    required String email,
    required String initials,
    required String status,
    required Color statusColor,
    required String statusSubtitle,
    required String role,
  }) {
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
                _heroUserBlock(
                  initials: initials,
                  name: name,
                  email: email,
                  status: status,
                  statusColor: statusColor,
                  statusSubtitle: statusSubtitle,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(
                      title: "Rol",
                      value: role.toUpperCase(),
                      color: _info,
                    ),
                    _HeroChip(
                      title: "Estado",
                      value: status,
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _heroUserBlock(
                    initials: initials,
                    name: name,
                    email: email,
                    status: status,
                    statusColor: statusColor,
                    statusSubtitle: statusSubtitle,
                  ),
                ),
                const SizedBox(width: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(
                      title: "Rol",
                      value: role.toUpperCase(),
                      color: _info,
                    ),
                    _HeroChip(
                      title: "Estado",
                      value: status,
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroUserBlock({
    required String initials,
    required String name,
    required String email,
    required String status,
    required Color statusColor,
    required String statusSubtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: _kyboAccent.withOpacity(.22),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Perfil Kybo",
                style: TextStyle(
                  color: Color(0xFFFFD89A),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email.isNotEmpty ? email : "Sin correo registrado",
                style: TextStyle(
                  color: Colors.white.withOpacity(.84),
                  fontSize: 13.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusPill(
                    text: status,
                    color: statusColor,
                  ),
                  _StatusPill(
                    text: statusSubtitle,
                    color: Colors.white54,
                    useLightText: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard({
    required BuildContext context,
    required bool isMobile,
    required String name,
    required String email,
    required String role,
    required String status,
    required Color statusColor,
    required Timestamp? createdAt,
    required Timestamp? lastLogin,
    required int? daysInactive,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: _kyboCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEBEEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: "Información del usuario",
            subtitle: "Datos generales y actividad de acceso",
          ),
          const SizedBox(height: 18),
          isMobile
              ? Column(
                  children: [
                    _infoCard("UID", userId, Icons.fingerprint_rounded),
                    const SizedBox(height: 12),
                    _infoCard("Nombre", name, Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _infoCard("Correo", email, Icons.mail_outline_rounded),
                    const SizedBox(height: 12),
                    _infoCard("Rol", role, Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _statusInfoCard(status, statusColor),
                    const SizedBox(height: 12),
                    _infoCard(
                      "Cuenta creada",
                      _formatTimeAgo(createdAt),
                      Icons.event_available_rounded,
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      "Último acceso",
                      _formatTimeAgo(lastLogin),
                      Icons.login_rounded,
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      "Fecha último acceso",
                      _formatDateTime(lastLogin),
                      Icons.schedule_rounded,
                    ),
                    if (daysInactive != null) ...[
                      const SizedBox(height: 12),
                      _infoCard(
                        "Días sin ingresar",
                        "$daysInactive",
                        Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ],
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _infoCard("UID", userId, Icons.fingerprint_rounded, width: 370),
                    _infoCard("Nombre", name, Icons.person_outline_rounded, width: 370),
                    _infoCard("Correo", email, Icons.mail_outline_rounded, width: 370),
                    _infoCard("Rol", role, Icons.badge_outlined, width: 370),
                    _statusInfoCard(status, statusColor, width: 370),
                    _infoCard(
                      "Cuenta creada",
                      _formatTimeAgo(createdAt),
                      Icons.event_available_rounded,
                      width: 370,
                    ),
                    _infoCard(
                      "Último acceso",
                      _formatTimeAgo(lastLogin),
                      Icons.login_rounded,
                      width: 370,
                    ),
                    _infoCard(
                      "Fecha último acceso",
                      _formatDateTime(lastLogin),
                      Icons.schedule_rounded,
                      width: 370,
                    ),
                    if (daysInactive != null)
                      _infoCard(
                        "Días sin ingresar",
                        "$daysInactive",
                        Icons.hourglass_bottom_rounded,
                        width: 370,
                      ),
                  ],
                ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserEditScreen(userId: userId),
                  ),
                );

                if (context.mounted && result == true) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text("Editar usuario"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kyboAccent,
                foregroundColor: _kyboPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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

  Widget _infoCard(
    String title,
    String value,
    IconData icon, {
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9F1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kyboPrimary.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kyboPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "No disponible",
                  style: const TextStyle(
                    color: _kyboPrimary,
                    fontSize: 13.6,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusInfoCard(
    String status,
    Color statusColor, {
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.verified_user_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Estado",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _HeroChip({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final bool useLightText;

  const _StatusPill({
    required this.text,
    required this.color,
    this.useLightText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: useLightText ? Colors.white.withOpacity(.10) : color.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: useLightText ? Colors.white.withOpacity(.14) : color.withOpacity(.18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: useLightText ? Colors.white : color,
          fontSize: 12.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}