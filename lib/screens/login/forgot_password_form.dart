import 'package:flutter/material.dart';

class ForgotPasswordForm extends StatelessWidget {

  final VoidCallback onBack;

  const ForgotPasswordForm({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Text(
            "Recuperar contraseña",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          const TextField(
            decoration: InputDecoration(
              labelText: "Correo electrónico",
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {},
            child: const Text("Enviar recuperación"),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onBack,
            child: const Text("Volver al login"),
          ),
        ],
      ),
    );
  }
}