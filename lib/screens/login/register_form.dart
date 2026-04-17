import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_alert.dart';
import '../main/main_layout.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onLogin;

  const RegisterForm({
    super.key,
    required this.onLogin,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _fieldBg = Color(0xFFF7F5FC);
  static const Color _fieldBorder = Color(0xFFE5DEF3);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();

  bool isLoading = false;
  bool _obscurePassword = true;

  bool _isValidEmail(String email) {
    return email.contains("@") && email.contains(".");
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 15,
      ),
      prefixIcon: Icon(
        icon,
        color: _kyboPrimary.withOpacity(.78),
        size: 22,
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey.shade500,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
          : null,
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: _kyboAccent,
          width: 1.6,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(.72),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            isPassword: isPassword,
          ),
        ),
      ],
    );
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showCustomAlert(
        context,
        message: "Completa todos los campos",
        type: AlertType.warning,
      );
      return;
    }

    if (!_isValidEmail(email)) {
      showCustomAlert(
        context,
        message: "Correo inválido",
        type: AlertType.warning,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await _auth.registerWithEmail(email, password);

      if (user == null) {
        throw Exception("No se pudo crear el usuario");
      }

      await _firestore.createUser(
        AppUser(
          uid: user.uid,
          name: name,
          email: email,
          role: 'user',
          isActive: true,
          failedAttempts: 0,
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainLayout(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al registrar";

      if (e.code == 'email-already-in-use') {
        mensaje = "Este correo ya está registrado";
      } else if (e.code == 'weak-password') {
        mensaje = "La contraseña debe tener al menos 6 caracteres";
      } else if (e.code == 'invalid-email') {
        mensaje = "Correo inválido";
      }

      showCustomAlert(
        context,
        message: mensaje,
        type: AlertType.error,
      );
    } catch (_) {
      showCustomAlert(
        context,
        message: "Error al guardar usuario",
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _googleRegister() async {
    setState(() => isLoading = true);

    try {
      final user = await _auth.loginWithGoogle();

      if (user == null) return;

      final email = user.email ?? "";
      final name = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : email.split('@')[0];

      final existingUser = await _firestore.getUser(user.uid);

      if (existingUser == null) {
        await _firestore.createUser(
          AppUser(
            uid: user.uid,
            name: name,
            email: email,
            role: 'user',
            isActive: true,
            failedAttempts: 0,
            lastLogin: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainLayout(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showCustomAlert(
        context,
        message: "Error con Google",
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  Widget _socialButton({
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 56,
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: _kyboPrimary.withOpacity(.10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white.withOpacity(.90),
        ),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _input(
          controller: nameController,
          label: "Nombre",
          hint: "Ingresa tu nombre",
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        _input(
          controller: emailController,
          label: "Correo",
          hint: "Ingresa tu correo",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _input(
          controller: passwordController,
          label: "Contraseña",
          hint: "Crea una contraseña",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kyboAccent, Color(0xFFFFC96F)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _kyboAccent.withOpacity(.24),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: _kyboPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kyboPrimary,
                      ),
                    )
                  : const Text(
                      "Crear cuenta",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "¿Ya tienes cuenta?",
              style: TextStyle(
                color: Colors.black.withOpacity(.58),
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: widget.onLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(left: 6),
                foregroundColor: _kyboPrimary,
              ),
              child: const Text(
                "Iniciar sesión",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              onTap: isLoading ? null : _googleRegister,
              child: Image.asset(
                "assets/images/google.png",
                width: 18,
              ),
            ),
            const SizedBox(width: 12),
            _socialButton(
              onTap: null,
              child: const Icon(
                Icons.apple,
                size: 18,
                color: _kyboPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}