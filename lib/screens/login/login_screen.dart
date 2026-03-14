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

  /// LAYOUT WEB
  Widget _webLayout() {
    return Row(
      children: [
        /// Panel izquierdo con imagen
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6A11CB),
                  Color(0xFF2575FC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 80,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Control Financiero",
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Organiza tus ingresos y gastos\n"
                      "de manera inteligente.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Panel derecho login
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                final offset = Tween(
                  begin: const Offset(1, 0),
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
              )),
            ),
          ),
        ),
      ],
    );
  }

  /// LAYOUT MOVIL
  Widget _mobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6A11CB),
            Color(0xFF2575FC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
            ),
            child: currentForm(),
          ),
        ),
      ),
    );
  }
}
