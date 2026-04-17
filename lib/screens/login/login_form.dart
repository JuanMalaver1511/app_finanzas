import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_alert.dart';
import '../admin/admin_screen.dart';
import '../../models/user_model.dart';
import '../main/main_layout.dart';

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
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _fieldBg = Color(0xFFF7F5FC);
  static const Color _fieldBorder = Color(0xFFE5DEF3);

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

  void _showResetDialog() {
    final emailCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 470),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3FC),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.16),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(.70),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recuperar contraseña",
                      style: TextStyle(
                        color: _kyboPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        height: 1.05,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Ingresa tu correo y te enviaremos un enlace de recuperación.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black.withOpacity(.60),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        hintText: "Correo electrónico",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: _kyboPrimary.withOpacity(.78),
                          size: 22,
                        ),
                        filled: true,
                        fillColor: _fieldBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
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
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                loading ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: _kyboPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kyboAccent, Color(0xFFFFC96F)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _kyboAccent.withOpacity(.24),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
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

                                        if (!context.mounted) return;
                                        Navigator.pop(context);

                                        showCustomAlert(
                                          context,
                                          message:
                                              "Correo enviado correctamente",
                                          type: AlertType.success,
                                        );
                                      } catch (_) {
                                        if (!context.mounted) return;
                                        showCustomAlert(
                                          context,
                                          message: "Error al enviar correo",
                                          type: AlertType.error,
                                        );
                                      }

                                      setStateModal(() => loading = false);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: _kyboPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _kyboPrimary,
                                      ),
                                    )
                                  : const Text(
                                      "Enviar",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
              builder: (_) => const MainLayout(),
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
          controller: emailController,
          label: "Correo",
          hint: "Ingresa tu correo",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _input(
          controller: passwordController,
          label: "Contraseña",
          hint: "Ingresa tu contraseña",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showResetDialog,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: _kyboPrimary,
            ),
            child: const Text(
              "¿Olvidaste tu contraseña?",
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
              onPressed: isLoading ? null : _login,
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
                      "Iniciar sesión",
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
              "¿No tienes cuenta?",
              style: TextStyle(
                color: Colors.black.withOpacity(.58),
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: widget.onRegister,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(left: 6),
                foregroundColor: _kyboPrimary,
              ),
              child: const Text(
                "Crear cuenta",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              onTap: isLoading ? null : _googleLogin,
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
