import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/custom_alert.dart';

class UserEditScreen extends StatefulWidget {
  final String userId;

  const UserEditScreen({super.key, required this.userId});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboPrimarySoft = Color(0xFF3B2F79);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _kyboBg = Color(0xFFF6F7FB);
  static const Color _kyboCard = Colors.white;
  static const Color _success = Color(0xFF16A34A);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF4F46E5);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String role = 'user';
  bool isActive = true;

  bool isLoading = true;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (!doc.exists) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final data = doc.data()!;

    nameController.text = (data['name'] ?? '').toString();
    emailController.text = (data['email'] ?? '').toString();
    role = (data['role'] ?? 'user').toString();
    isActive = data['isActive'] ?? true;

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    showCustomAlert(context, message: msg, type: AlertType.success);
  }

  void _showError(String msg) {
    showCustomAlert(context, message: msg, type: AlertType.error);
  }

  bool _validate() {
    if (nameController.text.trim().isEmpty) {
      _showError("El nombre no puede estar vacío");
      return false;
    }
    return true;
  }

  Future<void> _resetPassword() async {
    try {
      setState(() => isProcessing = true);

      final email = emailController.text.trim();

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() => isProcessing = false);
      _showSuccess("Correo de recuperación enviado");
    } catch (_) {
      if (mounted) {
        setState(() => isProcessing = false);
      }
      _showError("Error al enviar el correo");
    }
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'name': nameController.text.trim(),
        'role': role,
        'isActive': isActive,
      });

      if (!mounted) return;

      setState(() => isProcessing = false);
      Navigator.pop(context, true);

      Future.microtask(() {
        _showSuccess("Usuario actualizado correctamente");
      });
    } catch (_) {
      if (mounted) {
        setState(() => isProcessing = false);
      }
      _showError("No se pudo guardar la información");
    }
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

  Future<void> _delete() async {
    final confirm = await _confirmDelete();
    if (!confirm) return;

    try {
      setState(() => isProcessing = true);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();

      if (!mounted) return;

      setState(() => isProcessing = false);
      Navigator.pop(context, true);

      Future.microtask(() {
        _showSuccess("Usuario eliminado correctamente");
      });
    } catch (_) {
      if (mounted) {
        setState(() => isProcessing = false);
      }
      _showError("No se pudo eliminar el usuario");
    }
  }

  Color _roleColor() {
    return role == 'admin' ? _danger : _info;
  }

  String _roleLabel() {
    return role == 'admin' ? 'ADMIN' : 'USER';
  }

  Color _statusColor() {
    return isActive ? _success : _danger;
  }

  String _statusLabel() {
    return isActive ? 'ACTIVO' : 'BLOQUEADO';
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _kyboPrimary),
      filled: true,
      fillColor: enabled ? const Color(0xFFF9FAFD) : const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE7E9F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kyboPrimary, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: _kyboBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initials = nameController.text.trim().isNotEmpty
        ? nameController.text.trim()[0].toUpperCase()
        : "U";

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _kyboBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 20,
                isMobile ? 16 : 24,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context, isMobile),
                      const SizedBox(height: 18),
                      _buildHeroBanner(
                        isMobile: isMobile,
                        initials: initials,
                      ),
                      const SizedBox(height: 18),
                      _buildFormCard(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isProcessing)
          Container(
            color: Colors.black.withOpacity(0.28),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
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
                  "Editar usuario",
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: _kyboPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Actualiza el perfil, rol y estado del usuario",
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
    required String initials,
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
                _heroUserBlock(initials),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(
                      title: "Rol",
                      value: _roleLabel(),
                      color: _roleColor(),
                    ),
                    _HeroChip(
                      title: "Estado",
                      value: _statusLabel(),
                      color: _statusColor(),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _heroUserBlock(initials),
                ),
                const SizedBox(width: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(
                      title: "Rol",
                      value: _roleLabel(),
                      color: _roleColor(),
                    ),
                    _HeroChip(
                      title: "Estado",
                      value: _statusLabel(),
                      color: _statusColor(),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroUserBlock(String initials) {
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
                nameController.text.trim().isEmpty
                    ? "Sin nombre"
                    : nameController.text.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emailController.text.trim().isEmpty
                    ? "Sin correo"
                    : emailController.text.trim(),
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
                    text: _statusLabel(),
                    color: _statusColor(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isMobile) {
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
            title: "Configuración del usuario",
            subtitle: "Edita nombre, rol, estado y acceso",
          ),
          const SizedBox(height: 18),
          isMobile
              ? Column(
                  children: [
                    _buildNameField(),
                    const SizedBox(height: 14),
                    _buildEmailField(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildNameField()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildEmailField()),
                  ],
                ),
          const SizedBox(height: 18),
          isMobile
              ? Column(
                  children: [
                    _buildRoleField(),
                    const SizedBox(height: 14),
                    _buildStatusCard(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRoleField()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildStatusCard()),
                  ],
                ),
          const SizedBox(height: 20),
          _buildSecurityActions(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _danger,
                    side: BorderSide(color: _danger.withOpacity(.35)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Eliminar",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kyboAccent,
                    foregroundColor: _kyboPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Guardar",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(
        label: "Nombre",
        hint: "Nombre del usuario",
        icon: Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      enabled: false,
      decoration: _inputDecoration(
        label: "Correo",
        hint: "Correo del usuario",
        icon: Icons.mail_outline_rounded,
        enabled: false,
      ),
    );
  }

  Widget _buildRoleField() {
    return DropdownButtonFormField<String>(
      value: role,
      decoration: _inputDecoration(
        label: "Rol",
        hint: "Selecciona un rol",
        icon: Icons.badge_outlined,
      ),
      borderRadius: BorderRadius.circular(18),
      items: const [
        DropdownMenuItem(
          value: 'user',
          child: Text("Usuario"),
        ),
        DropdownMenuItem(
          value: 'admin',
          child: Text("Admin"),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => role = value);
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.toggle_on_outlined, color: _kyboPrimary),
              SizedBox(width: 8),
              Text(
                "Estado de acceso",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _kyboPrimary,
                  fontSize: 14.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Define si el usuario podrá ingresar a la plataforma.",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12.6,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: isActive,
            contentPadding: EdgeInsets.zero,
            activeColor: _success,
            title: Text(
              isActive ? "Usuario activo" : "Usuario bloqueado",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _kyboPrimary,
              ),
            ),
            subtitle: Text(
              isActive
                  ? "Puede acceder con normalidad"
                  : "Acceso restringido temporalmente",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.2,
              ),
            ),
            onChanged: (value) {
              setState(() => isActive = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kyboPrimary.withOpacity(.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kyboPrimary.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: _kyboPrimary, size: 18),
              SizedBox(width: 8),
              Text(
                "Acciones de seguridad",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _kyboPrimary,
                  fontSize: 14.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Envía un correo para que el usuario restablezca su contraseña.",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12.6,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetPassword,
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text("Restablecer contraseña"),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kyboAccent,
                side: const BorderSide(color: _kyboAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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

  const _StatusPill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}