import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_alert.dart';
import '../dashboard/dashboard_screen.dart';

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
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();

  bool isLoading = false;
  bool _obscurePassword = true;

  /// ==============================
  /// INPUT PRO
  /// ==============================
  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black45,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: Colors.black54),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFFFB84E),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  /// ==============================
  /// REGISTER
  /// ==============================
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
          builder: (_) => const DashboardScreen(),
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
    } catch (e) {
      showCustomAlert(
        context,
        message: "Error al guardar usuario",
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// ==============================
  /// GOOGLE REGISTER
  /// ==============================
  Future<void> _googleRegister() async {
    setState(() => isLoading = true);

    try {
      final user = await _auth.loginWithGoogle();

      if (user == null) return;

      final email = user.email ?? "";

      String name = user.displayName?.trim().isNotEmpty == true
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
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (_) {
      showCustomAlert(
        context,
        message: "Error con Google",
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// ==============================
  /// UI
  /// ==============================
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/images/logo.png", width: 55),
              const SizedBox(height: 12),

              const Text(
                "Crear cuenta",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 20),

              _input(
                controller: nameController,
                hint: "Nombre",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 12),

              _input(
                controller: emailController,
                hint: "Correo electrónico",
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 12),

              _input(
                controller: passwordController,
                hint: "Contraseña",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 18),

              /// 🔥 BOTÓN REGISTRARSE
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB84E),
                    elevation: 1.5,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          "Registrarse",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),

              // ✅ "Registrarse con Google" en negro
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: Image.asset("assets/images/google.png", width: 22),
                  label: const Text(
                    "Registrarse con Google",
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: isLoading ? null : _googleRegister,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ "Iniciar sesión" en negro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Ya tienes cuenta?"),
                  TextButton(
                    onPressed: widget.onLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      "Iniciar sesión",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
