import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';

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
          "Iniciar Sesión",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        /// EMAIL
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "Correo electrónico",
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
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
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        /// OLVIDÉ CONTRASEÑA
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingresa tu correo primero")),
                );
                return;
              }

              try {
                await _auth.resetPassword(emailController.text.trim());

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Revisa tu correo para recuperar la contraseña"),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                String mensaje = "Error al enviar correo";

                if (e.code == 'user-not-found') {
                  mensaje = "El correo no está registrado";
                } else if (e.code == 'invalid-email') {
                  mensaje = "Correo inválido";
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(mensaje)),
                );
              }
            },
            child: const Text(
              "¿Olvidaste tu contraseña?",
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),

        const SizedBox(height: 25),

        /// BOTON LOGIN
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
                    if (emailController.text.trim().isEmpty ||
                        passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Completa todos los campos")),
                      );
                      return;
                    }

                    setState(() => isLoading = true);

                    try {
                      final user = await _auth.loginWithEmail(
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
                          const SnackBar(content: Text("No se pudo iniciar sesión")),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String mensaje = "Error al iniciar sesión";

                      if (e.code == 'user-not-found') {
                        mensaje = "El usuario no existe";
                      } else if (e.code == 'wrong-password') {
                        mensaje = "Contraseña incorrecta";
                      } else if (e.code == 'invalid-email') {
                        mensaje = "Correo inválido";
                      } else if (e.code == 'invalid-credential') {
                        mensaje = "Credenciales incorrectas";
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(mensaje)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
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
                    "Ingresar",
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

        /// GOOGLE LOGIN
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            icon: Image.asset("assets/images/google.png", width: 22),
            label: Text(
              isLoading ? "Cargando..." : "Continuar con Google",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black12),
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

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("¿No tienes cuenta?"),
            TextButton(
              onPressed: widget.onRegister,
              child: const Text("Crear cuenta"),
            )
          ],
        )
      ],
    );
  }
}