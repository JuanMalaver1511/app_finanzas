import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/transaction_service.dart';
import '../../services/DeepSeek_IA.dart';
import '../../services/notificationIA.dart';

// ─── COLORES (misma paleta del proyecto) ─────────────────────────────────────
const _kDark = Color(0xFF1A1A2E);
const _kBg = Color(0xFFF5F6FA);
const _kCard = Colors.white;
const _kGrey = Color(0xFF9098A9);
const _kGreyLight = Color(0xFFEEF0F5);
const _kAmber = Color(0xFFE6A817);
const _kAmberLight = Color(0xFFFFF3D6);
const _kAmberDark = Color(0xFF9A6D00);
const _kGreen = Color(0xFF16A163);
const _kGreenLight = Color(0xFFE8F8F0);
const _kGreenDark = Color(0xFF0A6B40);
const _kRed = Color(0xFFD63031);
const _kRedLight = Color(0xFFFFF0F0);
const _kRedDark = Color(0xFF8B1A1A);

class IAInsightButton extends StatefulWidget {
  const IAInsightButton({super.key});

  @override
  State<IAInsightButton> createState() => _IAInsightButtonState();
}

class _IAInsightButtonState extends State<IAInsightButton>
    with SingleTickerProviderStateMixin {
  final ai = DeepSeekService();
  final noti = NotificationService();

  bool loading = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    noti.init();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

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
      'Diciembre'
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

      final respuesta = await ai.analizarFinanzas(
        ingresos: ingresos,
        gastos: gastos,
        deudas: 0,
        balance: balance,
        mes: mes,
      );

      if (!mounted) return;

      if (kIsWeb) {
        _showInsightDialog(
          mes: mes,
          ingresos: ingresos,
          gastos: gastos,
          balance: balance,
          respuesta: respuesta,
        );
      } else {
        await noti.mostrarNotificacion(
          '${_nombreMes(mes)} - Análisis financiero',
          respuesta,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _kDark,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: _kRed, size: 18),
                SizedBox(width: 10),
                Text('Error al analizar datos financieros',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
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
    required String respuesta,
  }) {
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? _kGreenDark : _kRedDark;
    final balanceBg = isPositive ? _kGreenLight : _kRedLight;
    final balanceLabel = isPositive ? 'Superávit' : 'Déficit';
    final balanceIcon =
        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header con gradiente ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A2E), Color(0xFF2D2B55)],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Análisis financiero',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _nombreMes(mes),
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(_),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Métricas ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    children: [
                      _metricTile(
                        label: 'Ingresos',
                        value: _formatMoney(ingresos),
                        icon: Icons.arrow_downward_rounded,
                        color: _kGreenDark,
                        bg: _kGreenLight,
                      ),
                      const SizedBox(width: 10),
                      _metricTile(
                        label: 'Gastos',
                        value: _formatMoney(gastos),
                        icon: Icons.arrow_upward_rounded,
                        color: _kRedDark,
                        bg: _kRedLight,
                      ),
                      const SizedBox(width: 10),
                      _metricTile(
                        label: balanceLabel,
                        value: _formatMoney(balance.abs()),
                        icon: balanceIcon,
                        color: balanceColor,
                        bg: balanceBg,
                      ),
                    ],
                  ),
                ),

                // ── Respuesta IA ────────────────────────────────────────────
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
                              'Recomendación',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.07)),
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

                // ── Footer ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kAmberLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 12, color: _kAmberDark),
                            const SizedBox(width: 5),
                            const Text('Generado por IA',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _kAmberDark,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(_),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                            color: _kDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
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
      ),
    );
  }

  Widget _metricTile({
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
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: loading ? 1.0 : _pulseAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: loading ? null : _analizar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            gradient: loading
                ? const LinearGradient(
                    colors: [Color(0xFF3A3A55), Color(0xFF3A3A55)])
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF2D2B55)],
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: loading
                ? []
                : [
                    BoxShadow(
                      color: _kDark.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                    color: Colors.white60,
                  ),
                )
              else
                const Icon(Icons.auto_awesome_rounded,
                    size: 17, color: Colors.white),
              const SizedBox(width: 9),
              Text(
                loading ? 'Analizando...' : 'Análisis con IA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
