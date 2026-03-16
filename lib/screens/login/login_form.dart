import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        const FlutterLogo(size: 60),

        const SizedBox(height: 20),

        const Text(
          "Iniciar sesión",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        /// EMAIL
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: "Correo electrónico",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// PASSWORD
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Contraseña",
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// BOTON LOGIN
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            onPressed: () async {

              final user = await _auth.loginWithEmail(
                emailController.text.trim(),
                passwordController.text.trim(),
              );

              if (user != null) {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Login exitoso"),
                  ),
                );

              } else {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Error al iniciar sesión"),
                  ),
                );

              }

            },

            child: const Text("Ingresar"),
          ),
        ),

        const SizedBox(height: 20),

        const Divider(),

        const SizedBox(height: 20),

        /// BOTON GOOGLE
        SizedBox(
          width: double.infinity,
          height: 50,

          child: OutlinedButton.icon(
            icon: Image.network(
              "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
              width: 20,
            ),
            label: const Text("Continuar con Google"),

            onPressed: () async {

              final user = await _auth.loginWithGoogle();

              if (user != null) {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Login con Google exitoso"),
                  ),
                );

              }

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