import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(
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

          /// NOMBRE
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Nombre",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

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

          const SizedBox(height: 25),

          /// BOTON REGISTRO
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

              onPressed: () async {

                final user = await _auth.registerWithEmail(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );

                if (user != null) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Usuario creado correctamente"),
                    ),
                  );

                  widget.onLogin();

                } else {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al registrar usuario"),
                    ),
                  );

                }

              },

              child: const Text("Registrarse"),
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
      ),
    );
  }
}