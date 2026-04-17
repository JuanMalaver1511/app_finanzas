import 'package:flutter/material.dart';

class ForgotPasswordForm extends StatelessWidget {
  final VoidCallback onBack;

  const ForgotPasswordForm({
    super.key,
    required this.onBack,
  });

  static const Color _kyboPrimary = Color(0xFF2B2257);
  static const Color _kyboPrimarySoft = Color(0xFF5B3FD1);
  static const Color _kyboAccent = Color(0xFFFFB84E);
  static const Color _fieldBg = Color(0xFFF7F5FC);
  static const Color _fieldBorder = Color(0xFFE5DEF3);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kyboPrimarySoft, _kyboPrimary],
              ),
              boxShadow: [
                BoxShadow(
                  color: _kyboPrimarySoft.withOpacity(.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Recuperar contraseña",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: _kyboPrimary,
              height: 1.05,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.",
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: Colors.black.withOpacity(.62),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "Correo electrónico",
            style: TextStyle(
              color: Colors.black.withOpacity(.72),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            decoration: InputDecoration(
              hintText: "Ingresa tu correo",
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: _kyboPrimary.withOpacity(.78),
                size: 22,
              ),
              filled: true,
              fillColor: _fieldBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: _kyboAccent,
                  width: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kyboAccent, Color(0xFFFFC96F)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _kyboAccent.withOpacity(.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: _kyboPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Enviar recuperación",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
              ),
              label: const Text(
                "Volver al login",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _kyboPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}