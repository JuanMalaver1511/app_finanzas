import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/custom_alert.dart';

class UserEditScreen extends StatefulWidget {
  final String userId;

  const UserEditScreen({super.key, required this.userId});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  String role = 'user';
  bool isActive = true;

  bool isLoading = true;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (!doc.exists) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final data = doc.data()!;

    nameController.text = data['name'] ?? '';
    emailController.text = data['email'] ?? '';
    role = data['role'] ?? 'user';
    isActive = data['isActive'] ?? true;

    setState(() => isLoading = false);
  }

  void _showSuccess(String msg) {
    showCustomAlert(context, message: msg, type: AlertType.success);
  }

  void _showError(String msg) {
    showCustomAlert(context, message: msg, type: AlertType.error);
  }

  void _showWarning(String msg) {
    showCustomAlert(context, message: msg, type: AlertType.warning);
  }

  bool _validate() {
    if (nameController.text.trim().isEmpty) {
      _showError("El nombre no puede estar vacío");
      return false;
    }
    return true;
  }

  /// ==============================
  /// RESET PASSWORD 
  /// ==============================
  Future<void> _resetPassword() async {
    try {
      setState(() => isProcessing = true);

      final email = emailController.text.trim();

      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() => isProcessing = false);

      _showSuccess("Correo de recuperación enviado");

    } catch (e) {
      setState(() => isProcessing = false);
      _showError("Error al enviar el correo");
    }
  }

  /// ==============================
  /// GUARDAR
  /// ==============================
  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => isProcessing = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'name': nameController.text.trim(),
      'role': role,
      'isActive': isActive,
    });

    if (!mounted) return;

    setState(() => isProcessing = false);

    Navigator.pop(context, true);

    Future.microtask(() {
      _showSuccess("Usuario actualizado correctamente");
    });
  }

  /// ==============================
  /// CONFIRM DELETE
  /// ==============================
  Future<bool> _confirmDelete() async {
    return await showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 50, color: Colors.red),
                  const SizedBox(height: 15),
                  const Text(
                    "Eliminar usuario",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Esta acción no se puede deshacer",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Eliminar"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  /// ==============================
  /// DELETE (FIX)
  /// ==============================
  Future<void> _delete() async {
    final confirm = await _confirmDelete();
    if (!confirm) return;

    Navigator.pop(context, true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .delete();
  }

  /// BADGES
  Widget _roleBadge() {
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.red.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? "ADMIN" : "USER",
        style: TextStyle(
          color: isAdmin ? Colors.red : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? "ACTIVO" : "BLOQUEADO",
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade100,
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

                      _header(context),

                      const SizedBox(height: 10),

                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.orange.shade200,
                        child: Text(
                          nameController.text.isNotEmpty
                              ? nameController.text[0].toUpperCase()
                              : "U",
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _roleBadge(),
                          const SizedBox(width: 10),
                          _statusBadge(),
                        ],
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Nombre",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: emailController,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: "Correo",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField(
                        value: role,
                        decoration: const InputDecoration(
                          labelText: "Rol",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text("Usuario")),
                          DropdownMenuItem(value: 'admin', child: Text("Admin")),
                        ],
                        onChanged: (value) {
                          setState(() => role = value.toString());
                        },
                      ),

                      const SizedBox(height: 10),

                      SwitchListTile(
                        value: isActive,
                        activeColor: const Color(0xFFFFB84E),
                        title: const Text("Usuario activo"),
                        onChanged: (value) {
                          setState(() => isActive = value);
                        },
                      ),

                      /// 🔥 BOTÓN RESET PASSWORD
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _resetPassword,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text("Restablecer contraseña"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFB84E),
                            side: const BorderSide(
                                color: Color(0xFFFFB84E)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _delete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text("Eliminar"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFFFB84E),
                              ),
                              child: const Text("Guardar"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        if (isProcessing)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 10),
        const Text(
          "Editar usuario",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}