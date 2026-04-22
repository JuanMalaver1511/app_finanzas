import 'package:flutter/material.dart';
import 'login_form.dart';
import 'register_form.dart';

enum AuthView { login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgTop = Color(0xFFF6F2FF);
  static const Color _bgBottom = Color(0xFFEDE7FB);
  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboPrimarySoft = Color(0xFF5B3FD1);
  static const Color _kyboPrimaryDark = Color(0xFF201942);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _phoneShell = Color(0xFFFBFAFE);
  static const Color _phoneInner = Color(0xFFF7F3FC);

  AuthView currentView = AuthView.login;

  late AnimationController _walletController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _walletController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _walletController,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _walletController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _walletController,
        curve: Curves.easeOutQuart,
      ),
    );

    _walletController.forward();
  }

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  void changeView(AuthView view) {
    setState(() {
      currentView = view;
    });
    _walletController.reset();
    _walletController.forward();
  }

  Widget currentForm() {
    switch (currentView) {
      case AuthView.register:
        return RegisterForm(onLogin: () => changeView(AuthView.login));
      case AuthView.login:
        return LoginForm(onRegister: () => changeView(AuthView.register));
    }
  }

  Widget _walletAnimated({required Widget child}) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 950;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Stack(
          children: [
            _backgroundDecor(),
            isWeb ? _webLayout() : _mobileLayout(),
          ],
        ),
      ),
    );
  }

  Widget _backgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -120,
          child: _glowBlob(
            size: 340,
            colors: [
              _kyboPrimarySoft.withOpacity(.18),
              _kyboPrimarySoft.withOpacity(.03),
            ],
          ),
        ),
        Positioned(
          bottom: -120,
          right: -80,
          child: _glowBlob(
            size: 320,
            colors: [
              _kyboAccent.withOpacity(.16),
              _kyboAccent.withOpacity(.02),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glowBlob({required double size, required List<Color> colors}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }

  Widget _webLayout() {
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.94, end: 1),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(.70),
                              Colors.white.withOpacity(.28),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kyboPrimary.withOpacity(.08),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/login.png",
                          width: 320,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [_kyboPrimaryDark, _kyboPrimarySoft],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        "Toma el control\nde tu dinero",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Organiza, ahorra y haz crecer tus finanzas con Kybo.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Colors.black.withOpacity(.60),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: 82,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [_kyboAccent, Color(0xFFFFD88E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kyboAccent.withOpacity(.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 10,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _phoneMockup(
                  key: ValueKey(currentView),
                  child: currentForm(),
                  isMobile: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: _phoneMockup(
              key: ValueKey(currentView),
              child: currentForm(),
              isMobile: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneMockup({
    required Widget child,
    required bool isMobile,
    Key? key,
  }) {
    return Container(
      key: key,
      width: isMobile ? 360 : 380,
      padding: EdgeInsets.all(isMobile ? 6 : 10),
      decoration: BoxDecoration(
        color: _phoneShell,
        borderRadius: BorderRadius.circular(isMobile ? 28 : 40),
        border: Border.all(
          color: Colors.white.withOpacity(.85),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: _kyboPrimary.withOpacity(.10),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _phoneInner,
          borderRadius: BorderRadius.circular(isMobile ? 22 : 32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header morado con animación billetera ────────────
            _walletAnimated(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kyboPrimarySoft,
                      _kyboPrimary,
                      _kyboPrimaryDark.withOpacity(0.9),
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMobile ? 22 : 26),
                    topRight: Radius.circular(isMobile ? 22 : 26),
                    bottomLeft: Radius.circular(isMobile ? 6 : 8),
                    bottomRight: Radius.circular(isMobile ? 6 : 8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kyboPrimarySoft.withOpacity(.35),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: _kyboPrimaryDark.withOpacity(.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 18,
                    isMobile ? 24 : 26,
                    isMobile ? 16 : 18,
                    isMobile ? 32 : 34,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Image.asset(
                            "assets/images/logoSinFondo.png",
                            height: isMobile ? 64 : 68,
                          ),
                        ),
                      ),
                      Text(
                        currentView == AuthView.login
                            ? "Iniciar sesión"
                            : "Crear cuenta",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentView == AuthView.login
                            ? "Accede a tu espacio financiero"
                            : "Crea tu cuenta en Kybo",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.85),
                          fontSize: isMobile ? 13 : 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Pliegue de la wallet
                      Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Formulario ───────────────────────────────────────
            Transform.translate(
              offset: Offset(0, isMobile ? -12 : -14),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 12),
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 18 : 18,
                  isMobile ? 18 : 18,
                  isMobile ? 18 : 18,
                  isMobile ? 14 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.90),
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  border: Border.all(
                    color: Colors.white.withOpacity(.70),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kyboPrimary.withOpacity(.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
            SizedBox(height: isMobile ? 0 : 4),
          ],
        ),
      ),
    );
  }
}
