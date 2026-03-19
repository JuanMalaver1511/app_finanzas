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

  /// REGISTER
  Future<void> _register() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showCustomAlert(
        context,
        message: "Completa todos los campos",
        type: AlertType.warning,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await _auth.registerWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        /// 🔥 GUARDAR EN FIRESTORE
        await _firestore.createUser(
          AppUser(
            uid: user.uid,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      }
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
      final msg = e.toString().replaceAll("Exception: ", "");

      showCustomAlert(
        context,
        message: msg,
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// GOOGLE REGISTER
  Future<void> _googleRegister() async {
    setState(() => isLoading = true);

    try {
      final user = await _auth.loginWithGoogle();

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException &&
          e.code == 'popup-closed-by-user') {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      showCustomAlert(
        context,
        message: "Error con Google",
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset("assets/images/logo.png", width: 70),
        const SizedBox(height: 20),
        const Text(
          "Crear cuenta",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),

        _input(
          controller: nameController,
          hint: "Nombre",
          icon: Icons.person_outline,
        ),

        const SizedBox(height: 16),

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

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB84E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("Registrarse",
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
            label: const Text("Registrarse con Google"),
            onPressed: isLoading ? null : _googleRegister,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("¿Ya tienes cuenta?"),
            TextButton(
              onPressed: widget.onLogin,
              child: const Text("Iniciar sesión"),
            )
          ],
        )
      ],
    );
  }
}