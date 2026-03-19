import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _auth = AuthService();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// LOGO
        Image.asset(
          "assets/images/logo.png",
          width: 70,
        ),

        const SizedBox(height: 20),

        const Text(
          "Crear cuenta",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        /// NOMBRE
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Nombre",
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// EMAIL
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "Correo electrónico",
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// PASSWORD
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Contraseña",
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 25),

        /// BOTON REGISTRO
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB84E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: isLoading
                ? null
                : () async {
                    if (nameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Completa todos los campos"),
                        ),
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No se pudo registrar"),
                          ),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String mensaje = "Error al registrar";

                      if (e.code == 'email-already-in-use') {
                        mensaje = "Este correo ya está registrado";
                      } else if (e.code == 'weak-password') {
                        mensaje =
                            "La contraseña debe tener al menos 6 caracteres";
                      } else if (e.code == 'invalid-email') {
                        mensaje = "Correo inválido";
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(mensaje)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error inesperado: $e")),
                      );
                    }

                    if (mounted) setState(() => isLoading = false);
                  },
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    "Registrarse",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        /// GOOGLE REGISTER
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            icon: Image.asset("assets/images/google.png", width: 22),
            label: Text(
              isLoading ? "Cargando..." : "Registrarse con Google",
              style: const TextStyle(color: Colors.black87),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: isLoading
                ? null
                : () async {
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
                      /// 👉 usuario cerró popup (NO error)
                      if (e is FirebaseAuthException &&
                          e.code == 'popup-closed-by-user') {
                        if (mounted) setState(() => isLoading = false);
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error con Google")),
                      );
                    }

                    if (mounted) setState(() => isLoading = false);
                  },
          ),
        ),

        const SizedBox(height: 20),

        /// LOGIN LINK
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