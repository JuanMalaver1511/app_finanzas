import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_wrapper.dart';
import '../profile/profile_screen.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/dashboard/top_bar.dart';
import '../../widgets/dashboard/add_transaction_dialog.dart';

// ─── COLORES ───────────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF6366F1); // azul moderno tipo fintech
const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
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
  'Otross': Icons.more_horiz,
};

Color _catColor(String cat) => kCategoryColors[cat] ?? const Color(0xFFAAAAAA);
IconData _catIcon(String cat) => kCategoryIcons[cat] ?? Icons.receipt_outlined;

// ─── DASHBOARD SCREEN ──────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TransactionService _txService;
  late final String _uid;
  late final String _userName;

  void _showEditDialog(AppTransaction tx) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => AddTransactionDialog(
        initial: tx, // ✅ pre-llena el formulario
        onAdd: (updated) => _txService.update(updated), // ✅ llama update
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _uid = user.uid;
    _userName = user.displayName ?? user.email?.split('@').first ?? 'Usuario';
    _txService = TransactionService(_uid);
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: kBg,
      // ✅ FAB en móvil para agregar transacción
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: kAmber,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                        _WelcomeBanner(name: _userName),
                        const SizedBox(height: 16),
                        _BalanceCards(
                          balance: balance,
                          income: income,
                          expense: expense,
                        ),
                        const SizedBox(height: 16),

                        if (transactions.isNotEmpty) ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                return Column(
                                  children: [
                                    _DonutCard(transactions: transactions),
                                    const SizedBox(height: 16),
                                    _BudgetBarsCard(transactions: transactions),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child:
                                        _DonutCard(transactions: transactions),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _BudgetBarsCard(
                                        transactions: transactions),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        _TransactionsCard(
                          transactions: transactions,
                          onDelete: (id) => _txService.delete(id),
                          onEdit: _showEditDialog, // ✅ nuevo
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

// ─── WELCOME BANNER ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return '¡Buenos días';
    if (h < 18) return '¡Buenas tardes';
    return '¡Buenas noches';
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF4DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFFFE0A0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kAmber.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: isMobile ? 44 : 52,
            height: isMobile ? 44 : 52,
            decoration: BoxDecoration(
              color: kAmber.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kAmber.withOpacity(0.6), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: kAmber,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: kGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: kDark,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Finanzas al día',
                      style: TextStyle(fontSize: 11, color: kGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Icono decorativo — oculto en móvil para ahorrar espacio
          if (!isMobile)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kAmber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kAmber.withOpacity(0.3), width: 1),
              ),
              child:
                  const Icon(Icons.bar_chart_rounded, color: kAmber, size: 26),
            ),
        ],
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
            value: 'COP ${balance.toStringAsFixed(2)}',
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
                  value: 'COP ${income.toStringAsFixed(2)}',
                  icon: Icons.trending_up_rounded,
                  iconColor: kGreen,
                  valueColor: kGreen,
                ),
              ),
              const SizedBox(width: 10),
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
                    Text('COP ${e.value.toStringAsFixed(0)}',
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
  const _BudgetBarsCard({required this.transactions});

  static const Map<String, double> _budgets = {
    'Alimentación': 600000, // mercado básico mensual
    'Transporte': 200000, // bus, gasolina, etc
    'Entretenimiento': 150000,
    'Salud': 250000,
    'Educación': 300000,
    'Hogar': 1500000, // arriendo + gastos
    'Ropa': 150000,
    'Servicios': 300000, // agua, luz, internet
    'Otros': 150000,
  };

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};
    for (final tx in transactions.where((t) => !t.isIncome)) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
    }

    final cats = _budgets.keys.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Presupuestos',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
          const SizedBox(height: 16),
          ...cats.map((cat) {
            final spent = totals[cat] ?? 0.0;
            final budget = _budgets[cat]!;
            final pct = (spent / budget).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: _catColor(cat), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(cat,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kDark)),
                      ]),
                      Text(
                          'COP ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10, color: kGrey)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation(_catColor(cat)),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── TRANSACTIONS CARD ─────────────────────────────────────────────────────────

class _TransactionsCard extends StatelessWidget {
  final List<AppTransaction> transactions;
  final void Function(String id) onDelete;
  final void Function(AppTransaction tx) onEdit; // ✅

  const _TransactionsCard({
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transacciones recientes',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: kDark)),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: kGrey),
                    SizedBox(height: 10),
                    Text('Sin transacciones aún',
                        style: TextStyle(color: kGrey, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Presiona + para comenzar',
                        style: TextStyle(color: kGrey, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...transactions.asMap().entries.map((e) => Column(
                  children: [
                    _TxRow(
                      tx: e.value,
                      onDelete: () => onDelete(e.value.id),
                      onEdit: () => onEdit(e.value),
                    ),
                    if (e.key < transactions.length - 1)
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
            '${tx.isIncome ? '+' : '-'} COP ${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.bold,
                color: tx.isIncome ? kGreen : kRed),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onEdit,
            child: const Icon(Icons.edit_outlined, size: 18, color: kGrey),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: const Icon(Icons.delete_outline, size: 18, color: kGrey),
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

BoxDecoration _cardDecoration() => BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
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
