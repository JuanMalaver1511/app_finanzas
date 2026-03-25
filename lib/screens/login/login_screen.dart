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
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.center, 
                  children: [
                    /// IMAGEN 
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 700),
                      tween: Tween(begin: 0.9, end: 1),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        "assets/images/login.png",
                        width: 360,
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// TITULO
                    const Text(
                      "Toma el control de tu dinero",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// SUBTITULO
                    const Text(
                      "Organiza, ahorra y haz crecer tus finanzas con Kybo.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// LINEA DECORATIVA (detalle pro)
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFB84E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// DERECHA (FORMULARIO)
        Expanded(
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: Center(
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
                child: SingleChildScrollView(
                  child: Container(
                    key: ValueKey(currentView),
                    width: 420,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Container(
          key: ValueKey(currentView),
          width: 350,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: currentForm(),
        ),
      ),
    );
  }
}
