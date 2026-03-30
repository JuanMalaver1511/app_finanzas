import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_alert.dart';
import '../dashboard/dashboard_screen.dart';
import '../admin/admin_screen.dart';
import '../../models/user_model.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onRegister;

  const LoginForm({
    super.key,
    required this.onRegister,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();

  bool isLoading = false;
  bool _obscurePassword = true;

  bool _isValidEmail(String email) {
    return email.contains("@") && email.contains(".");
  }

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
  /// RECUPERAR CONTRASEÑA
  /// ==============================
  void _showResetDialog() {
    final emailCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Recuperar contraseña"),
              content: TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  hintText: "Correo electrónico",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();

                          if (!_isValidEmail(email)) {
                            showCustomAlert(
                              context,
                              message: "Correo inválido",
                              type: AlertType.warning,
                            );
                            return;
                          }

                          setStateModal(() => loading = true);

                          try {
                            await _auth.resetPassword(email);

                            Navigator.pop(context);

                            showCustomAlert(
                              context,
                              message: "Correo enviado correctamente",
                              type: AlertType.success,
                            );
                          } catch (_) {
                            showCustomAlert(
                              context,
                              message: "Error al enviar correo",
                              type: AlertType.error,
                            );
                          }

                          setStateModal(() => loading = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB84E),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Enviar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ==============================
  /// LOGIN
  /// ==============================
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
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
      final user = await _auth.loginWithEmail(email, password);

      if (!mounted) return;

      if (user != null) {
        final userData = await _firestore.getUser(user.uid);

        if (userData != null && userData.isActive == false) {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          showCustomAlert(
            context,
            message: "Tu cuenta está bloqueada",
            type: AlertType.error,
          );

          setState(() => isLoading = false);

          return; 
        }

        await _firestore.updateUserLoginData(user.uid);

        final role = userData?.role ?? 'user';

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      final email = emailController.text.trim();
      await _firestore.incrementFailedAttemptsByEmail(email);

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        showCustomAlert(
          context,
          message: "Este usuario no está registrado",
          type: AlertType.warning,
        );

        Future.delayed(const Duration(milliseconds: 800), () {
          widget.onRegister();
        });

        if (mounted) setState(() => isLoading = false);
        return;
      }

      if (e.code == 'wrong-password') {
        showCustomAlert(
          context,
          message: "Contraseña incorrecta",
          type: AlertType.error,
        );
      } else {
        showCustomAlert(
          context,
          message: "Error al iniciar sesión",
          type: AlertType.error,
        );
      }
    } catch (_) {
      showCustomAlert(
        context,
        message: "Error inesperado",
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _googleLogin() async {
    setState(() => isLoading = true);

    try {
      final user = await _auth.loginWithGoogle();

      if (!mounted) return;

      if (user != null) {
        final userData = await _firestore.getUser(user.uid);

        if (userData != null && userData.isActive == false) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          showCustomAlert(
            context,
            message: "Tu cuenta está bloqueada",
            type: AlertType.error,
          );
          if (mounted) setState(() => isLoading = false);
          return;
        }

        if (userData == null) {
          await _firestore.createUser(AppUser(
            uid: user.uid,
            name: user.displayName ?? 'Usuario',
            email: user.email ?? '',
            role: 'user',
            isActive: true,
            createdAt: DateTime.now(),
          ));
        } else {
          await _firestore.updateUserLoginData(user.uid);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      if (!errStr.contains('cross-origin') &&
          !errStr.contains('coop') &&
          !errStr.contains('window.close')) {
        showCustomAlert(
          context,
          message: "Error con Google",
          type: AlertType.error,
        );
      }
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
                "Iniciar Sesión",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 4),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
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
                          "Iniciar Sesión",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
              // ✅ "¿Olvidaste tu contraseña?" centrado y en negro
              Center(
                child: TextButton(
                  onPressed: _showResetDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 14),

              // ✅ "Continuar con Google" en negro
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: Image.asset("assets/images/google.png", width: 22),
                  label: const Text(
                    "Continuar con Google",
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: isLoading ? null : _googleLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ "Crear cuenta" en negro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes cuenta?"),
                  TextButton(
                    onPressed: widget.onRegister,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      "Crear cuenta",
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
