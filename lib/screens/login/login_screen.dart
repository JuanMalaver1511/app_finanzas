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
      backgroundColor: const Color(0xFFF5F5F5),
      body: isWeb ? _webLayout() : _mobileLayout(),
    );
  }

  /// WEB
  Widget _webLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.8, end: 1),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 120,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Control Financiero",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Organiza tus ingresos y gastos\nde manera inteligente.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: Container(
            color: Colors.white,
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

  /// MOBILE
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