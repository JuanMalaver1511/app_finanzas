import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/common/custom_alert.dart';

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({super.key});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
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
  bool isLoading = false;

  bool _validate() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      showCustomAlert(
        context,
        message: "El nombre es obligatorio",
        type: AlertType.warning,
      );
      return false;
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      showCustomAlert(
        context,
        message: "Correo inválido",
        type: AlertType.warning,
      );
      return false;
    }

    return true;
  }

  Future<void> _createUser() async {
    if (!_validate()) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      await functions.httpsCallable('createUserByAdmin').call({
        'name': nameController.text.trim(),
        'email': email,
        'role': role,
        'isActive': isActive,
      });

      if (!mounted) return;

      showCustomAlert(
        context,
        message: "Usuario creado y correo enviado correctamente",
        type: AlertType.success,
      );

      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      String message = "Error inesperado";

      switch (e.code) {
        case 'already-exists':
          message = "Este correo ya está registrado";
          break;
        case 'invalid-argument':
          message = "Datos inválidos";
          break;
        case 'internal':
          message = e.message ?? "Error del servidor";
          break;
        default:
          message = e.message ?? "Error desconocido";
      }

      showCustomAlert(
        context,
        message: message,
        type: AlertType.error,
      );
    } catch (_) {
      showCustomAlert(
        context,
        message: "Error inesperado",
        type: AlertType.error,
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _kyboPrimary),
      filled: true,
      fillColor: const Color(0xFFF9FAFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE7E9F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kyboPrimary, width: 1.4),
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

    return Scaffold(
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
                  _buildHeroBanner(isMobile),
                  const SizedBox(height: 18),
                  _buildFormCard(isMobile),
                ],
              ),
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
                  "Crear usuario",
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: _kyboPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Configura un nuevo acceso para la plataforma",
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
                _heroTextBlock(),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _HeroChip(
                      title: "Acceso",
                      value: "Nuevo",
                      color: _success,
                    ),
                    _HeroChip(
                      title: "Estado",
                      value: "Configurable",
                      color: _warning,
                    ),
                    _HeroChip(
                      title: "Rol",
                      value: "Admin / User",
                      color: _info,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 4, child: _heroTextBlock()),
                const SizedBox(width: 18),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(
                      title: "Acceso",
                      value: "Nuevo",
                      color: _success,
                    ),
                    _HeroChip(
                      title: "Estado",
                      value: "Configurable",
                      color: _warning,
                    ),
                    _HeroChip(
                      title: "Rol",
                      value: "Admin / User",
                      color: _info,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroTextBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kybo Admin",
          style: TextStyle(
            color: Color(0xFFFFD89A),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Nuevo usuario para la plataforma",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Completa los datos básicos, define el rol y el estado inicial del usuario antes de enviarlo.",
          style: TextStyle(
            color: Colors.white.withOpacity(.84),
            fontSize: 13.2,
            height: 1.38,
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
            title: "Información del usuario",
            subtitle: "Datos principales para crear el acceso",
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
          _buildInfoPanel(),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _createUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kyboAccent,
                foregroundColor: _kyboPrimary,
                disabledBackgroundColor: _kyboAccent.withOpacity(.65),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _kyboPrimary,
                      ),
                    )
                  : const Text(
                      "Crear usuario",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      textCapitalization: TextCapitalization.words,
      decoration: _inputDecoration(
        label: "Nombre",
        hint: "Ej. Juan Pérez",
        icon: Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration(
        label: "Correo",
        hint: "correo@empresa.com",
        icon: Icons.mail_outline_rounded,
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
                "Estado inicial",
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
            "Define si el usuario podrá ingresar apenas sea creado.",
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
                  ? "Podrá acceder desde el inicio"
                  : "Se crea sin acceso habilitado",
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

  Widget _buildInfoPanel() {
    final roleLabel = role == 'admin' ? 'Administrador' : 'Usuario';
    final statusLabel = isActive ? 'Activo' : 'Bloqueado';

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
              Icon(Icons.insights_rounded, color: _kyboPrimary, size: 18),
              SizedBox(width: 8),
              Text(
                "Resumen de configuración",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _kyboPrimary,
                  fontSize: 14.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniInfoChip(
                label: "Rol",
                value: roleLabel,
                color: _info,
              ),
              _MiniInfoChip(
                label: "Estado",
                value: statusLabel,
                color: isActive ? _success : _danger,
              ),
              const _MiniInfoChip(
                label: "Correo",
                value: "Se enviará acceso",
                color: _warning,
              ),
            ],
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

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniInfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
          ),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: _UserCreateScreenState._kyboPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}