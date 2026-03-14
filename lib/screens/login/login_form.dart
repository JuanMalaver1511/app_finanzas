import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {

  final VoidCallback onRegister;

  const LoginForm({
    super.key,
    required this.onRegister,
  });

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

        const SizedBox(height: 20),

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
            onPressed: () {},
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
            onPressed: () {},
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("¿No tienes cuenta?"),

            TextButton(
              onPressed: onRegister,
              child: const Text("Crear cuenta"),
            )

          ],
        )

      ],
    );
  }
}