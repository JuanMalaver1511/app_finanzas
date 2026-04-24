import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/transaction_service.dart';
import '../../services/DeepSeek_IA.dart';

// ─── COLORES KYBO ────────────────────────────────────────────────────────────
const _kDark = Color(0xFF1A1A2E);
const _kBg = Color(0xFFF5F6FA);
const _kCard = Colors.white;
const _kAmber = Color(0xFFFFBB4E);
const _kAmberLight = Color(0xFFFFF3D6);
const _kAmberDark = Color(0xFF9A6D00);
const _kGreenLight = Color(0xFFE8F8F0);
const _kGreenDark = Color(0xFF0A6B40);
const _kRed = Color(0xFFD63031);
const _kRedLight = Color(0xFFFFF0F0);
const _kRedDark = Color(0xFF8B1A1A);
const _kPurple = Color(0xFF6366F1);

class IAInsightButton extends StatefulWidget {
  const IAInsightButton({super.key});

  @override
  State<IAInsightButton> createState() => _IAInsightButtonState();
}

class _IAInsightButtonState extends State<IAInsightButton> {
  final ai = DeepSeekService();

  bool loading = false;

  String _formatMoney(double value) =>
      '\$${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String _nombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  Future<void> _analizar() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final service = TransactionService(user.uid);
      final data = await service.getResumenMensual();

      final ingresos = (data['ingresos'] ?? 0).toDouble();
      final gastos = (data['gastos'] ?? 0).toDouble();
      final balance = (data['balance'] ?? 0).toDouble();
      final mes = data['mes'] ?? DateTime.now().month;

      final debtsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('debts')
          .get();

      final deudas = debtsSnapshot.docs.fold<double>(0.0, (acc, doc) {
        final debtData = doc.data();
        final cuota = debtData['cuota_mensual'];
        final saldoActual = debtData['saldo_actual'];

        final cuotaVal = cuota is int
            ? cuota.toDouble()
            : cuota is double
                ? cuota
                : 0.0;

        final saldoVal = saldoActual is int
            ? saldoActual.toDouble()
            : saldoActual is double
                ? saldoActual
                : 0.0;

        return saldoVal > 0 ? acc + cuotaVal : acc;
      });

      final respuesta = await ai.analizarFinanzas(
        ingresos: ingresos,
        gastos: gastos,
        deudas: deudas,
        balance: balance,
        mes: mes,
      );

      if (!mounted) return;

      _showInsightDialog(
        mes: mes,
        ingresos: ingresos,
        gastos: gastos,
        balance: balance,
        deudas: deudas,
        respuesta: respuesta,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _kDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: _kRed, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No se pudo generar el análisis financiero.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  void _showInsightDialog({
    required int mes,
    required double ingresos,
    required double gastos,
    required double balance,
    required double deudas,
    required String respuesta,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isPositive = balance >= 0;

    final balanceColor = isPositive ? _kGreenDark : _kRedDark;
    final balanceBg = isPositive ? _kGreenLight : _kRedLight;
    final balanceLabel = isPositive ? 'Superávit' : 'Déficit';
    final balanceIcon =
        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    const debtColor = _kRedDark;
    const debtBg = _kRedLight;
    const debtIcon = Icons.credit_card_rounded;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kDark, Color(0xFF2D2B55)],
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(26)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Análisis financiero IA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Resumen de ${_nombreMes(mes)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogCtx),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: isMobile
                        ? Column(
                            children: [
                              _metricTileH(
                                label: 'Ingresos',
                                value: _formatMoney(ingresos),
                                icon: Icons.arrow_downward_rounded,
                                color: _kGreenDark,
                                bg: _kGreenLight,
                              ),
                              const SizedBox(height: 8),
                              _metricTileH(
                                label: 'Gastos',
                                value: _formatMoney(gastos),
                                icon: Icons.arrow_upward_rounded,
                                color: _kRedDark,
                                bg: _kRedLight,
                              ),
                              const SizedBox(height: 8),
                              _metricTileH(
                                label: balanceLabel,
                                value: _formatMoney(balance.abs()),
                                icon: balanceIcon,
                                color: balanceColor,
                                bg: balanceBg,
                              ),
                              const SizedBox(height: 8),
                              _metricTileH(
                                label: 'Deudas',
                                value: _formatMoney(deudas),
                                icon: debtIcon,
                                color: debtColor,
                                bg: debtBg,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              _metricTileV(
                                label: 'Ingresos',
                                value: _formatMoney(ingresos),
                                icon: Icons.arrow_downward_rounded,
                                color: _kGreenDark,
                                bg: _kGreenLight,
                              ),
                              const SizedBox(width: 10),
                              _metricTileV(
                                label: 'Gastos',
                                value: _formatMoney(gastos),
                                icon: Icons.arrow_upward_rounded,
                                color: _kRedDark,
                                bg: _kRedLight,
                              ),
                              const SizedBox(width: 10),
                              _metricTileV(
                                label: balanceLabel,
                                value: _formatMoney(balance.abs()),
                                icon: balanceIcon,
                                color: balanceColor,
                                bg: balanceBg,
                              ),
                              const SizedBox(width: 10),
                              _metricTileV(
                                label: 'Deudas',
                                value: _formatMoney(deudas),
                                icon: debtIcon,
                                color: debtColor,
                                bg: debtBg,
                              ),
                            ],
                          ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _kAmber,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Recomendación de Kybo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _kDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.06),
                              ),
                            ),
                            child: Text(
                              respuesta,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kDark,
                                height: 1.65,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _kAmberLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 12,
                                color: _kAmberDark,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Generado por IA',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _kAmberDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogCtx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: _kPurple,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricTileV({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTileH({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : _analizar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: loading ? const Color(0xFF32324A) : _kPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            else
              const Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: Colors.white,
              ),
            const SizedBox(width: 9),
            Text(
              loading ? 'Analizando...' : 'Análisis con IA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
