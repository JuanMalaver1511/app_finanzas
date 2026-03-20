import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_alert.dart';
import '../dashboard/dashboard_screen.dart';
import '../admin/admin_screen.dart';

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

  bool _isValidEmail(String email) {
    return email.contains("@") && email.contains(".");
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// ==============================
  /// 🔐 RECUPERAR CONTRASEÑA (FIX)
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
  /// LOGIN PRO CON SEGURIDAD
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

        /// 🚫 BLOQUEADO
        if (userData != null && userData.isActive == false) {
          showCustomAlert(
            context,
            message: "Tu cuenta está bloqueada",
            type: AlertType.error,
          );
          setState(() => isLoading = false);
          return;
        }

        /// 🔄 RESET LOGIN DATA
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

      /// 🔥 SUMAR INTENTOS FALLIDOS
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

  /// ==============================
  /// GOOGLE LOGIN
  /// ==============================
  Future<void> _googleLogin() async {
    setState(() => isLoading = true);

    try {
      final user = await _auth.loginWithGoogle();

      if (!mounted) return;

      if (user != null) {
        final userData = await _firestore.getUser(user.uid);

        if (userData != null && userData.isActive == false) {
          showCustomAlert(
            context,
            message: "Tu cuenta está bloqueada",
            type: AlertType.error,
          );
          return;
        }

        await _firestore.updateUserLoginData(user.uid);

        final role = userData?.role ?? 'user';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset("assets/images/logo.png", width: 70),
        const SizedBox(height: 20),
        const Text("Iniciar Sesión",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),

        _input(
          controller: emailController,
          hint: "Correo electrónico",
          icon: Icons.email_outlined,
        ),

        const SizedBox(height: 16),

        _input(
          controller: passwordController,
          hint: "Contraseña",
          icon: Icons.lock_outline,
          isPassword: true,
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showResetDialog, // 🔥 YA FUNCIONA
            child: const Text("¿Olvidaste tu contraseña?"),
          ),
        ),

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB84E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("Ingresar",
                    style: TextStyle(color: Colors.black)),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            icon: Image.asset("assets/images/google.png", width: 22),
            label: const Text("Continuar con Google"),
            onPressed: isLoading ? null : _googleLogin,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("¿No tienes cuenta?"),
            TextButton(
              onPressed: widget.onRegister,
              child: const Text("Crear cuenta"),
            )
          ],
        ),
      ],
    );
  }
}