import 'package:flutter/material.dart';

class RegisterForm extends StatelessWidget {

  final VoidCallback onLogin;

  const RegisterForm({
    super.key,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        const FlutterLogo(size: 60),

        const SizedBox(height: 20),

        const Text(
          "Crear cuenta",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        TextField(
          decoration: InputDecoration(
            labelText: "Nombre",
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          decoration: InputDecoration(
            labelText: "Correo electrónico",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Contraseña",
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          height: 50,

          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2575FC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            child: const Text("Registrarse"),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("¿Ya tienes cuenta?"),

            TextButton(
              onPressed: onLogin,
              child: const Text("Iniciar sesión"),
            )

          ],
        )

      ],
    );
  }
}