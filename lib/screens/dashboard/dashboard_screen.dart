import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_wrapper.dart';
import '../profile/profile_screen.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/dashboard/top_bar.dart';
import '../../widgets/dashboard/add_transaction_dialog.dart';
import 'package:intl/intl.dart';
import '../../widgets/IA/ia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifications/notifications_screen.dart';
import '../../services/goal_service.dart';
import '../../models/goal_model.dart';
import '../../utils/goal_calculator.dart';

// ─── COLORES ───────────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF6366F1); // azul moderno tipo fintech
const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const KDarkB = Color.fromARGB(255, 40, 40, 88);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color.fromARGB(255, 29, 126, 69);
const kRed = Color(0xFFE74C3C);
const kGreenBtn = Color(0xFF27AE60);

// ─── CATEGORÍAS ────────────────────────────────────────────────────────────────

const kCategoryColors = {
  'Hogar': Color(0xFF4A9B8E),
  'Alimentación': Color(0xFF5BB85D),
  'Servicios': Color(0xFF5BA0D0),
  'Transporte': Color(0xFF3B6FBF),
  'Salud': Color(0xFF9B5BB8),
  'Educación': Color(0xFFD4A017),
  'Entretenimiento': Color(0xFFE05C5C),
  'Ropa': Color(0xFFB85B8A),
  'Ingreso': Color(0xFF2ECC71),
  'Trabajo': Color(0xFFFFBB4E),
  'Otros': Color(0xFFAAAAAA),
};

const kCategoryIcons = {
  'Hogar': Icons.home_outlined,
  'Alimentación': Icons.shopping_cart_outlined,
  'Servicios': Icons.electrical_services_outlined,
  'Transporte': Icons.directions_car_outlined,
  'Salud': Icons.fitness_center,
  'Educación': Icons.school_outlined,
  'Entretenimiento': Icons.tv_outlined,
  'Ropa': Icons.checkroom_outlined,
  'Ingreso': Icons.trending_up,
  'Trabajo': Icons.laptop_mac,
  'Otros': Icons.more_horiz,
};

Color _catColor(String cat) => kCategoryColors[cat] ?? const Color(0xFFAAAAAA);
IconData _catIcon(String cat) => kCategoryIcons[cat] ?? Icons.receipt_outlined;

// ─── DASHBOARD SCREEN ──────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onChange;

  const DashboardScreen({
    super.key,
    required this.onChange,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _HeroBalanceCard extends StatefulWidget {
  final String name;
  final double balance;
  final double income;
  final double expense;
  final VoidCallback onAdd;

  const _HeroBalanceCard({
    required this.name,
    required this.balance,
    required this.income,
    required this.expense,
    required this.onAdd,
  });

  @override
  State<_HeroBalanceCard> createState() => _HeroBalanceCardState();
}

class _HeroBalanceCardState extends State<_HeroBalanceCard> {
  bool _hideBalance = false;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _initials {
    final parts = widget.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
  }

  double get _expensePercent {
    if (widget.income <= 0) return 0;
    return (widget.expense / widget.income).clamp(0.0, 1.5);
  }

  String _getInsight() {
    if (widget.income == 0 && widget.expense == 0) {
      return 'Empieza registrando tus movimientos';
    }

    if (widget.balance < 0) {
      return 'Puedes optimizar tus gastos';
    }

    if (widget.income > 0 && widget.expense > widget.income * 0.8) {
      return 'Estás cerca de tu límite';
    }

    return 'Vas bien este mes';
  }

  String _monthlyHint() {
    if (widget.income <= 0 && widget.expense <= 0) {
      return 'Registra tus ingresos y gastos para ver tu resumen.';
    }

    if (widget.income <= 0) {
      return 'Aún no tienes ingresos registrados este mes.';
    }

    final percent = (widget.expense / widget.income * 100).round();

    if (widget.balance < 0) {
      return 'Tus gastos superan tus ingresos este mes.';
    }

    return 'Has usado el $percent% de tus ingresos registrados.';
  }

  Color get _statusColor {
    if (widget.balance < 0) return kRed;
    if (widget.income > 0 && widget.expense > widget.income * 0.8) {
      return kAmber;
    }
    return kGreen;
  }

  String _moneyOrHidden(double value) {
    if (_hideBalance) return r'$••••••• COP';
    return _formatMoney(value);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF191936),
            Color(0xFF22264A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              IAInsightButton(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: isMobile ? 46 : 54,
                height: isMobile ? 46 : 54,
                decoration: BoxDecoration(
                  color: kAmber.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAmber.withOpacity(0.35)),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: kAmber,
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 17 : 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Tu dinero disponible',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _hideBalance = !_hideBalance),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _hideBalance
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white.withOpacity(0.82),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _moneyOrHidden(widget.balance),
              key: ValueKey('${_hideBalance}_${widget.balance}'),
              style: TextStyle(
                color:
                    widget.balance < 0 ? const Color(0xFFFF6B5F) : Colors.white,
                fontSize: isMobile ? 28 : 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _statusColor.withOpacity(0.28)),
                ),
                child: Text(
                  _getInsight(),
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Text(
                  _monthlyHint(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (widget.income > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: _expensePercent.clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: Colors.white.withOpacity(0.09),
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isMobile)
            Column(
              children: [
                _heroMiniStat(
                  icon: Icons.south_rounded,
                  color: kGreen,
                  label: 'Ingresos',
                  value: _moneyOrHidden(widget.income),
                ),
                const SizedBox(height: 10),
                _heroMiniStat(
                  icon: Icons.north_rounded,
                  color: kRed,
                  label: 'Gastos',
                  value: _moneyOrHidden(widget.expense),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _heroMiniStat(
                    icon: Icons.south_rounded,
                    color: kGreen,
                    label: 'Ingresos',
                    value: _moneyOrHidden(widget.income),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _heroMiniStat(
                    icon: Icons.north_rounded,
                    color: kRed,
                    label: 'Gastos',
                    value: _moneyOrHidden(widget.expense),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _heroMiniStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.085),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onOpenBudgets;

  const _QuickActionsRow({
    required this.onAdd,
    required this.onOpenBudgets,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_rounded,
            label: isMobile ? 'Movimiento' : 'Nuevo movimiento',
            color: kAmber,
            onTap: onAdd,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: isMobile ? 'Presupuesto' : 'Ver presupuesto',
            color: kPrimary,
            onTap: onOpenBudgets,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAECEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardInsightCard extends StatelessWidget {
  final List<AppTransaction> transactions;
  final double income;
  final double expense;
  final double balance;

  const _DashboardInsightCard({
    required this.transactions,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final currentMonthExpenses = transactions.where((t) {
      return !t.isIncome &&
          t.date.year == now.year &&
          t.date.month == now.month;
    }).toList();

    final Map<String, double> totals = {};
    for (final tx in currentMonthExpenses) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }

    final topCategory = totals.entries.isEmpty
        ? null
        : (totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first;

    final message = _message(topCategory);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kAmber.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: kAmber),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight KYBO',
                  style: TextStyle(
                    color: kDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _message(MapEntry<String, double>? topCategory) {
    if (income == 0 && expense == 0) {
      return 'Registra tus primeros movimientos para empezar a recibir recomendaciones.';
    }

    if (balance < 0) {
      return 'Tus gastos superan tus ingresos. Revisa tus categorías con mayor consumo.';
    }

    if (topCategory != null) {
      return 'Este mes tu mayor gasto está en ${topCategory.key}. Puedes revisarlo en reportes.';
    }

    if (income > 0 && expense <= income * 0.7) {
      return 'Buen ritmo: tus gastos están por debajo de tus ingresos.';
    }

    return 'Sigue registrando tus movimientos para mejorar el análisis financiero.';
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TransactionService _txService;
  late final String _uid;
  String _userName = 'Usuario';
  late final GoalService _goalService;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _uid = user.uid;
    _userName = user.displayName ?? user.email?.split('@').first ?? 'Usuario';
    _txService = TransactionService(_uid);
    _goalService = GoalService();

    Future.delayed(const Duration(milliseconds: 700), () {
      _checkIncomeReminder();
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => AddTransactionDialog(
        onAdd: (tx) => _txService.add(tx),
      ),
    );
  }

  void _showEditDialog(AppTransaction tx) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => AddTransactionDialog(
        initial: tx,
        onAdd: (updated) => _txService.update(updated),
      ),
    );
  }

  String _currentIncomePeriodKey({
    required String frequency,
    required List<int> paymentDays,
  }) {
    final now = DateTime.now();

    if (frequency == 'biweekly' && paymentDays.length >= 2) {
      final sorted = [...paymentDays]..sort();
      final firstDay = sorted.first;
      final secondDay = sorted.last;

      if (now.day >= secondDay) {
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-q2';
      }

      if (now.day >= firstDay) {
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-q1';
      }

      final prevMonth = DateTime(now.year, now.month - 1);
      return '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}-q2';
    }

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-monthly';
  }

  double _incomeAmountForPeriod({
    required String frequency,
    required double baseMonthlyIncome,
  }) {
    if (frequency == 'biweekly') {
      return baseMonthlyIncome / 2;
    }
    return baseMonthlyIncome;
  }

  bool _shouldAskToday({
    required String frequency,
    required List<int> paymentDays,
  }) {
    final today = DateTime.now();

    for (final day in paymentDays) {
      final start = DateTime(today.year, today.month, day);
      final end = start.add(const Duration(days: 5));

      final isInsideWindow = !today.isBefore(start) && !today.isAfter(end);

      if (isInsideWindow) {
        return true;
      }
    }

    if (frequency == 'biweekly' && paymentDays.isNotEmpty) {
      final sorted = [...paymentDays]..sort();
      final lastDay = sorted.last;

      final lastStart = DateTime(today.year, today.month - 1, lastDay);
      final lastEnd = lastStart.add(const Duration(days: 5));

      final isCrossMonthWindow =
          !today.isBefore(lastStart) && !today.isAfter(lastEnd);

      if (isCrossMonthWindow) {
        return true;
      }
    }

    return false;
  }

  Future<void> _checkIncomeReminder() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('settings')
        .doc('finance')
        .get();

    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    final baseMonthlyIncome =
        ((data['baseMonthlyIncome'] ?? 0) as num).toDouble();
    final financialProfileCompleted = data['financialProfileCompleted'] == true;

    if (!financialProfileCompleted || baseMonthlyIncome <= 0) return;

    final rawDays = data['paymentDays'];
    if (rawDays is! List || rawDays.isEmpty) return;

    final paymentDays = rawDays
        .map((e) => e is int ? e : int.tryParse(e.toString()))
        .whereType<int>()
        .toList()
      ..sort();

    if (paymentDays.isEmpty) return;

    final frequency = (data['incomeFrequency'] ?? 'monthly').toString();

    final periodKey = _currentIncomePeriodKey(
      frequency: frequency,
      paymentDays: paymentDays,
    );

    final prefsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('settings')
        .doc('income_control')
        .get();

    if (prefsDoc.exists) {
      final lastShownPeriod = prefsDoc.data()?['lastShownPeriod'];
      if (lastShownPeriod == periodKey) return;
    }

    if (_shouldAskToday(
          frequency: frequency,
          paymentDays: paymentDays,
        ) &&
        mounted) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('income_control')
          .set({
        'lastShownPeriod': periodKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showIncomeDialog(
        frequency: frequency,
        periodKey: periodKey,
      );
    }
  }

  void _showIncomeDialog({
    required String frequency,
    required String periodKey,
  }) {
    final label = frequency == 'biweekly'
        ? 'Confirma si ya recibiste este pago quincenal.'
        : 'Confirma si ya recibiste tu pago programado.';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('¿Recibiste tu ingreso?'),
        content: Text(label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aún no'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createIncomeTransaction(periodKey: periodKey);
            },
            child: const Text('Sí, recibido'),
          ),
        ],
      ),
    );
  }

  Future<void> _createIncomeTransaction({
    required String periodKey,
  }) async {
    final financeDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('settings')
        .doc('finance')
        .get();

    if (!financeDoc.exists) return;

    final data = financeDoc.data();
    if (data == null) return;

    final frequency = (data['incomeFrequency'] ?? 'monthly').toString();
    final baseMonthlyIncome =
        ((data['baseMonthlyIncome'] ?? 0) as num).toDouble();

    if (baseMonthlyIncome <= 0) return;

    final amount = _incomeAmountForPeriod(
      frequency: frequency,
      baseMonthlyIncome: baseMonthlyIncome,
    );

    final existing = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .where('source', isEqualTo: 'scheduled_income')
        .where('periodKey', isEqualTo: periodKey)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .add({
      'title': frequency == 'biweekly' ? 'Pago quincenal' : 'Salario',
      'amount': amount,
      'isIncome': true,
      'categoryName': 'Trabajo',
      'category': 'Trabajo',
      'source': 'scheduled_income',
      'periodKey': periodKey,
      'date': Timestamp.now(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: kBg,
      body: StreamBuilder<List<AppTransaction>>(
        stream: _txService.stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kAmber));
          }

          final transactions = snapshot.data ?? [];

          final income = transactions
              .where((t) => t.isIncome)
              .fold(0.0, (s, t) => s + t.amount);
          final expense = transactions
              .where((t) => !t.isIncome)
              .fold(0.0, (s, t) => s + t.amount);
          final balance = income - expense;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TopBar(
                  onNew: _showAddDialog,
                  showNewButton: true,
                  onNotifications: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  onProfile: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  onLogout: _logout,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_uid)
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            final data = userSnapshot.data?.data()
                                as Map<String, dynamic>?;

                            final profileName =
                                (data?['displayName'] ?? '').toString().trim();

                            final name = profileName.isNotEmpty
                                ? profileName
                                : _userName;

                            return _HeroBalanceCard(
                              name: name,
                              balance: balance,
                              income: income,
                              expense: expense,
                              onAdd: _showAddDialog,
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        _DashboardInsightCard(
                          transactions: transactions,
                          income: income,
                          expense: expense,
                          balance: balance,
                        ),
                        const SizedBox(height: 16),

                        if (transactions.isNotEmpty) ...[
                          _BudgetBarsCard(
                            transactions: transactions,
                            onOpenBudgets: () => widget.onChange(2),
                          ),
                          const SizedBox(height: 16),
                        ],

                        _GoalsHighlightCard(
                          goalService: _goalService,
                          onOpenGoals: () => widget.onChange(4),
                        ),
                        const SizedBox(height: 16),

                        _TransactionsCard(
                          transactions: transactions,
                          onDelete: (id) => _txService.delete(id),
                          onEdit: _showEditDialog,
                          onViewAll: () => widget.onChange(1),
                        ),

                        // Espacio extra en móvil para el FAB
                        if (isMobile) const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── BALANCE CARDS ─────────────────────────────────────────────────────────────

class _BalanceCards extends StatelessWidget {
  final double balance, income, expense;
  const _BalanceCards(
      {required this.balance, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // ✅ En móvil: balance arriba, ingresos y gastos abajo lado a lado
      return Column(
        children: [
          _StatCard(
            label: 'Balance total',
            value: _formatMoney(balance),
            icon: Icons.account_balance_wallet_outlined,
            iconColor: kAmber,
            valueColor: kDark,
            fullWidth: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Ingresos',
                  value: _formatMoney(balance),
                  icon: Icons.trending_up_rounded,
                  iconColor: kGreen,
                  valueColor: kGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Gastos',
                  value: _formatMoney(balance),
                  icon: Icons.trending_down_rounded,
                  iconColor: kRed,
                  valueColor: kRed,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Desktop: las 3 en fila
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Balance total',
            value: 'COP ${balance.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_outlined,
            iconColor: kAmber,
            valueColor: kDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Ingresos',
            value: 'COP ${income.toStringAsFixed(2)}',
            icon: Icons.trending_up_rounded,
            iconColor: kGreen,
            valueColor: kGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Gastos',
            value: 'COP ${expense.toStringAsFixed(2)}',
            icon: Icons.trending_down_rounded,
            iconColor: kRed,
            valueColor: kRed,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor, valueColor;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label,
                    style: const TextStyle(fontSize: 12, color: kGrey)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── DONUT CHART ───────────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  final List<AppTransaction> transactions;
  const _DonutCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};
    for (final tx in transactions.where((t) => !t.isIncome)) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }
    final total = totals.values.fold(0.0, (s, v) => s + v);
    if (total == 0) {
      return _emptyCard('Gastos por categoría', 'Sin gastos aún');
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gastos por categoría',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _DonutPainter(
                  data: entries
                      .map((e) => MapEntry(e.key, e.value / total))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...entries.take(7).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            color: _catColor(e.key), shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(e.key,
                            style:
                                const TextStyle(fontSize: 12, color: kDark))),
                    Text('${(e.value / total * 100).toInt()}%',
                        style: const TextStyle(fontSize: 11, color: kGrey)),
                    const SizedBox(width: 8),
                    Text(_formatMoney(e.value),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kDark)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  _DonutPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const stroke = 26.0;
    double start = -math.pi / 2;

    for (final e in data) {
      final sweep = 2 * math.pi * e.value;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep - 0.04,
        false,
        Paint()
          ..color = _catColor(e.key)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.data != data;
}

// ─── BUDGET BARS ───────────────────────────────────────────────────────────────

class _BudgetBarsCard extends StatelessWidget {
  final List<AppTransaction> transactions;
  final VoidCallback onOpenBudgets;

  const _BudgetBarsCard({
    required this.transactions,
    required this.onOpenBudgets,
  });

  String get _monthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(_monthKey)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingCard();
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onOpenBudgets,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(radius: 22),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kAmber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: kAmber,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presupuesto del mes',
                            style: TextStyle(
                              color: kDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configura tus límites para controlar mejor tus gastos.',
                            style: TextStyle(
                              color: kGrey,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: kGrey),
                  ],
                ),
              ),
            ),
          );
        }

        final now = DateTime.now();

        final currentMonthTransactions = transactions.where((t) {
          return !t.isIncome &&
              t.date.year == now.year &&
              t.date.month == now.month;
        }).toList();

        final Map<String, double> totals = {};
        for (final tx in currentMonthTransactions) {
          totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
        }

        final items = docs
            .map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {
                'name': (data['categoryName'] ?? '').toString(),
                'planned': ((data['planned'] ?? 0) as num).toDouble(),
                'color': (data['color'] ?? '#6366F1').toString(),
              };
            })
            .where((i) => (i['name'] as String).isNotEmpty)
            .toList();

        final totalBudget =
            items.fold<double>(0, (sum, i) => sum + (i['planned'] as double));
        final totalSpent = totals.values.fold<double>(0, (sum, v) => sum + v);
        final remaining = totalBudget - totalSpent;

        final totalProgress =
            totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

        final sortedItems = [...items]..sort((a, b) {
            final aName = a['name'] as String;
            final bName = b['name'] as String;
            final aPlanned = a['planned'] as double;
            final bPlanned = b['planned'] as double;
            final aSpent = totals[aName] ?? 0.0;
            final bSpent = totals[bName] ?? 0.0;
            final aPct = aPlanned > 0 ? aSpent / aPlanned : 0.0;
            final bPct = bPlanned > 0 ? bSpent / bPlanned : 0.0;
            return bPct.compareTo(aPct);
          });

        final previewItems = sortedItems.take(3).toList();
        final progressColor = totalProgress >= 1
            ? kRed
            : totalProgress >= 0.8
                ? kAmber
                : kPrimary;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onOpenBudgets,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 18 : 20),
              decoration: _cardDecoration(radius: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.pie_chart_outline_rounded,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Presupuesto del mes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: kDark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Resumen rápido de tus límites',
                              style: TextStyle(
                                fontSize: 12,
                                color: kGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${(totalProgress * 100).round()}%',
                          style: TextStyle(
                            color: progressColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: totalProgress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFEAECEF),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalProgress >= 1
                        ? 'Superaste tu presupuesto del mes'
                        : 'Vas ${(totalProgress * 100).round()}% del presupuesto mensual',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetResumeBox(
                          label: 'Gastado',
                          value: _formatMoney(totalSpent, compact: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BudgetResumeBox(
                          label: remaining >= 0 ? 'Disponible' : 'Excedido',
                          value: _formatMoney(remaining.abs(), compact: true),
                          danger: remaining < 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BudgetResumeBox(
                          label: 'Total',
                          value: _formatMoney(totalBudget, compact: true),
                        ),
                      ),
                    ],
                  ),
                  if (previewItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...previewItems.map((item) {
                      final name = item['name'] as String;
                      final planned = item['planned'] as double;
                      final spent = totals[name] ?? 0.0;
                      final pct =
                          planned > 0 ? (spent / planned).clamp(0.0, 1.0) : 0.0;
                      final exceeded = spent > planned;
                      final color = exceeded ? kRed : _catColor(name);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kDark,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(pct * 100).round()}%',
                              style: TextStyle(
                                color: exceeded ? kRed : kGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 22),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(width: 12),
          Text(
            'Cargando presupuesto...',
            style: TextStyle(color: kGrey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BudgetResumeBox extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;

  const _BudgetResumeBox({
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: danger ? kRed.withOpacity(0.08) : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: danger ? kRed.withOpacity(0.16) : const Color(0xFFEAECEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: danger ? kRed : kGrey,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: danger ? kRed : kDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TRANSACTIONS CARD ─────────────────────────────────────────────────────────

class _TransactionsCard extends StatelessWidget {
  final List<AppTransaction> transactions;
  final void Function(String id) onDelete;
  final void Function(AppTransaction tx) onEdit;
  final VoidCallback onViewAll;

  const _TransactionsCard({
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final recentTransactions = transactions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimos movimientos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: kDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tus 5 transacciones más recientes',
                      style: TextStyle(
                        fontSize: 12,
                        color: kGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text(
                  'Ver todos',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: kGrey),
                    SizedBox(height: 10),
                    Text(
                      'Sin transacciones aún',
                      style: TextStyle(color: kGrey, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Presiona + para comenzar',
                      style: TextStyle(color: kGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTransactions.asMap().entries.map((e) => Column(
                  children: [
                    _TxRow(
                      tx: e.value,
                      onDelete: () => onDelete(e.value.id),
                      onEdit: () => onEdit(e.value),
                    ),
                    if (e.key < recentTransactions.length - 1)
                      Divider(height: 1, color: Colors.grey[100]),
                  ],
                )),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final AppTransaction tx;
  final VoidCallback onDelete;
  final VoidCallback onEdit; // ✅

  const _TxRow({
    required this.tx,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _catColor(tx.category);
    final icon = _catIcon(tx.category);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  isMobile
                      ? tx.category
                      : '${tx.category} · ${_formatDate(tx.date)}',
                  style: const TextStyle(fontSize: 11, color: kGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${tx.isIncome ? '+' : '-'} ${_formatMoney(tx.amount)}',
            style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.bold,
                color: tx.isIncome ? kGreen : kRed),
          ),
          const SizedBox(width: 4),
          // Botones de editar y eliminar con backgrounds separados
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.edit_outlined, size: 16, color: kAmber),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.delete_outline, size: 16, color: kRed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar transacción'),
        content: Text('¿Eliminar "${tx.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Eliminar', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── HELPERS ───────────────────────────────────────────────────────────────────

BoxDecoration _cardDecoration({double radius = 16}) => BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3))
      ],
    );

Widget _emptyCard(String title, String msg) => Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
          const SizedBox(height: 20),
          const Icon(Icons.pie_chart_outline, size: 40, color: kGrey),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 8),
        ],
      ),
    );

String _formatMoney(double value, {bool compact = false}) {
  if (compact) {
    if (value >= 1000000) {
      final v = value / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)} M';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)} K';
    }
    return value.toStringAsFixed(0);
  }

  final formatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '',
    decimalDigits: 0,
  );
  return '${formatter.format(value)} COP';
}

Color _parseColor(String? hex) {
  if (hex == null || hex.trim().isEmpty) {
    return const Color(0xFFCBD5E1);
  }

  final clean = hex.replaceAll('#', '').trim();

  if (clean.length != 6) {
    return const Color(0xFFCBD5E1);
  }

  try {
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return const Color(0xFFCBD5E1);
  }
}

// ─────────────────────────────────────────────
// GOALS HIGHLIGHT (DASHBOARD)
// ─────────────────────────────────────────────

class _GoalsHighlightCard extends StatelessWidget {
  final GoalService goalService;
  final VoidCallback onOpenGoals;

  const _GoalsHighlightCard({
    required this.goalService,
    required this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GoalModel>>(
      stream: goalService.streamGoals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                SizedBox(width: 10),
                Text(
                  'Cargando metas...',
                  style: TextStyle(
                    color: kGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: const Text(
              'No se pudieron cargar las metas.',
              style: TextStyle(
                color: kDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final goals = snapshot.data ?? [];

        if (goals.isEmpty) {
          return _GoalsDashboardEmpty(onOpenGoals: onOpenGoals);
        }

        final visibleGoals = _pickGoals(goals);

        final activeGoals =
            goals.where((g) => g.status != GoalStatus.completed).length;
        final completedGoals =
            goals.where((g) => g.status == GoalStatus.completed).length;
        final totalSaved =
            goals.fold<double>(0, (sum, item) => sum + item.savedAmount);

        final isMobile = MediaQuery.of(context).size.width < 700;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus metas',
                          style: TextStyle(
                            color: kDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Revisa tus objetivos más importantes del momento.',
                          style: TextStyle(
                            color: kGrey,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: onOpenGoals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KDarkB,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ver todas las metas',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _GoalSummaryChip(
                    title: 'Activas',
                    value: '$activeGoals',
                    icon: Icons.flag_rounded,
                  ),
                  _GoalSummaryChip(
                    title: 'Cumplidas',
                    value: '$completedGoals',
                    icon: Icons.verified_rounded,
                  ),
                  _GoalSummaryChip(
                    title: 'Ahorrado',
                    value: _formatMoney(totalSaved, compact: true),
                    icon: Icons.savings_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isMobile)
                Column(
                  children: visibleGoals
                      .map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalDashboardTile(goal: goal),
                        ),
                      )
                      .toList(),
                )
              else
                Row(
                  children: visibleGoals
                      .asMap()
                      .entries
                      .map(
                        (entry) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right:
                                  entry.key == visibleGoals.length - 1 ? 0 : 12,
                            ),
                            child: _GoalDashboardTile(goal: entry.value),
                          ),
                        ),
                      )
                      .toList(),
                ),
              if (isMobile) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onOpenGoals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ver todas las metas',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<GoalModel> _pickGoals(List<GoalModel> goals) {
    final sorted = [...goals];

    int priority(GoalModel goal) {
      switch (goal.status) {
        case GoalStatus.delayed:
          return 0;
        case GoalStatus.atRisk:
          return 1;
        case GoalStatus.active:
          return 2;
        case GoalStatus.completed:
          return 3;
      }
    }

    sorted.sort((a, b) {
      final p = priority(a).compareTo(priority(b));
      if (p != 0) return p;
      return a.deadline.compareTo(b.deadline);
    });

    return sorted.take(2).toList();
  }
}

class _GoalsDashboardEmpty extends StatelessWidget {
  final VoidCallback onOpenGoals;

  const _GoalsDashboardEmpty({
    required this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tus metas',
            style: TextStyle(
              color: kDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aún no has creado metas. Empieza con una meta de ahorro y hazle seguimiento desde aquí.',
            style: TextStyle(
              color: kGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onOpenGoals,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.flag_rounded),
            label: const Text(
              'Crear meta',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSummaryChip extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _GoalSummaryChip({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kAmber, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: kDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: kGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalDashboardTile extends StatelessWidget {
  final GoalModel goal;

  const _GoalDashboardTile({
    required this.goal,
  });

  String _formatShortDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return kGreenBtn;
      case GoalStatus.atRisk:
        return kAmber;
      case GoalStatus.delayed:
        return kRed;
      case GoalStatus.completed:
        return kPrimary;
    }
  }

  IconData _statusIcon(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return Icons.trending_up_rounded;
      case GoalStatus.atRisk:
        return Icons.warning_amber_rounded;
      case GoalStatus.delayed:
        return Icons.access_time_filled_rounded;
      case GoalStatus.completed:
        return Icons.verified_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculation = GoalCalculator.calculate(
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      deadline: goal.deadline,
      frequency: goal.savingFrequency,
      now: DateTime.now(),
    );

    final progress = (goal.progress * 100).round();
    final statusColor = _statusColor(goal.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(goal.status),
                      color: statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      GoalCalculator.statusLabel(goal.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$progress%',
            style: const TextStyle(
              color: kDark,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEAECEF),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatMoney(goal.savedAmount, compact: true)} de ${_formatMoney(goal.targetAmount, compact: true)}',
            style: const TextStyle(
              color: kGrey,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfoChip(
                icon: Icons.event_rounded,
                text: _formatShortDate(goal.deadline),
              ),
              _MiniInfoChip(
                icon: Icons.payments_rounded,
                text: _formatMoney(
                  calculation.suggestedAmountPerPeriod,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: kDark,
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
