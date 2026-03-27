import 'package:flutter/material.dart';
import 'login_form.dart';
import 'register_form.dart';

enum AuthView { login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthView currentView = AuthView.login;

  void changeView(AuthView view) {
    setState(() {
      currentView = view;
    });
  }

  Widget currentForm() {
    switch (currentView) {
      case AuthView.register:
        return RegisterForm(
          onLogin: () => changeView(AuthView.login),
        );
      default:
        return LoginForm(
          onRegister: () => changeView(AuthView.register),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isWeb ? _webLayout() : _mobileLayout(),
    );
  }

  /// ==============================
  /// WEB (DISEÑO PRO)
  /// ==============================
  Widget _webLayout() {
    return Row(
      children: [
        /// IZQUIERDA (IMAGEN + MENSAJE)
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 700),
                      tween: Tween(begin: 0.9, end: 1),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Image.asset("assets/images/login.png", width: 280),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Toma el control de tu dinero",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Organiza, ahorra y haz crecer tus finanzas con Kybo.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB84E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// DERECHA (FORMULARIO) — 👇 fix aquí
        Expanded(
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: Center(
              // centra vertical y horizontal
              child: SingleChildScrollView(
                // scroll si la pantalla es muy baja
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey(currentView),
                    width: 380,
                    // ✅ SIN height fijo — el contenido decide el alto
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: currentForm(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ==============================
  /// MOBILE (LIMPIO)
  /// ==============================
  Widget _mobileLayout() {
    return Center(
      child: SingleChildScrollView(
        // 👈 scroll en móvil también
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey(currentView),
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: currentForm(),
          ),
        ),
      ),
    );
  }
}
