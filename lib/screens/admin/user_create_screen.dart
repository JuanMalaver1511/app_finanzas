import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/common/custom_alert.dart';

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({super.key});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  String role = 'user';
  bool isActive = true;
  bool isLoading = false;

  bool _validate() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      showCustomAlert(context,
          message: "El nombre es obligatorio", type: AlertType.warning);
      return false;
    }

    final emailRegex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      showCustomAlert(context,
          message: "Correo inválido", type: AlertType.warning);
      return false;
    }

    return true;
  }

  Future<void> _createUser() async {
    if (!_validate()) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();

      /// 🔥 USAR REGIÓN (SOLUCIÓN CORS)
      final functions =
          FirebaseFunctions.instanceFor(region: 'us-central1');

      await functions.httpsCallable('createUserByAdmin').call({
        'name': nameController.text.trim(),
        'email': email,
        'role': role,
        'isActive': isActive,
      });

      if (!mounted) return;

      showCustomAlert(
        context,
        message: "Usuario creado y correo enviado correctamente",
        type: AlertType.success,
      );

      Navigator.pop(context);

    } on FirebaseFunctionsException catch (e) {
      String message = "Error inesperado";

      switch (e.code) {
        case 'already-exists':
          message = "Este correo ya está registrado";
          break;
        case 'invalid-argument':
          message = "Datos inválidos";
          break;
        case 'internal':
          message = e.message ?? "Error del servidor";
          break;
        default:
          message = e.message ?? "Error desconocido";
      }

      showCustomAlert(
        context,
        message: message,
        type: AlertType.error,
      );

    } catch (e) {
      showCustomAlert(
        context,
        message: "Error inesperado",
        type: AlertType.error,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Crear usuario"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                children: [

                  /// NOMBRE
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// EMAIL
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Correo",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// ROL
                  DropdownButtonFormField(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text("Usuario")),
                      DropdownMenuItem(value: 'admin', child: Text("Admin")),
                    ],
                    onChanged: (value) {
                      setState(() => role = value.toString());
                    },
                    decoration: const InputDecoration(
                      labelText: "Rol",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// ESTADO
                  SwitchListTile(
                    value: isActive,
                    title: const Text("Usuario activo"),
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  /// BOTÓN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _createUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB84E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text("Crear usuario"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}