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
      body: isWeb ? _webLayout() : _mobileLayout(),
    );
  }

  /// WEB LAYOUT
  Widget _webLayout() {
    return Row(
      children: [

        /// PANEL IZQUIERDO
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    /// LOGO
                    Image.asset(
                      "assets/images/logo.png",
                      width: 120,
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Control Financiero",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Organiza tus ingresos y gastos\nde manera inteligente.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// PANEL DERECHO LOGIN
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {

                  final offset = Tween(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(
                    position: offset,
                    child: child,
                  );
                },
                child: SingleChildScrollView(
                  child: Container(
                    key: ValueKey(currentView),
                    width: 420,
                    padding: const EdgeInsets.all(40),
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

  /// MOBILE LAYOUT
  Widget _mobileLayout() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),

            child: currentForm(),
          ),
        ),
      ),
    );
  }
}