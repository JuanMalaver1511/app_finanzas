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

            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Colors.black54,
            ),

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

            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Colors.black54,
            ),

            filled: true,
            fillColor: const Color(0xFFF2F2F2),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
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

            onPressed: () async {

              final user = await _auth.loginWithEmail(
                emailController.text.trim(),
                passwordController.text.trim(),
              );

              if (!mounted) return;

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

            child: const Text(
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

            icon: Image.network(
              "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
              width: 20,
            ),

            label: const Text("Continuar con Google"),

            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),

            onPressed: () async {

              final user = await _auth.loginWithGoogle();

              if (!mounted) return;

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