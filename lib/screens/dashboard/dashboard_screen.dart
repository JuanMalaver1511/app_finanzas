import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';

// ─── COLORES ───────────────────────────────────────────────────────────────────

const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color.fromARGB(255, 29, 126, 69);
const kRed = Color(0xFFE74C3C);
const kGreenBtn = Color(0xFF27AE60);

// ─── MODELO ────────────────────────────────────────────────────────────────────

class AppTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;

  AppTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  // Convierte Firestore → AppTransaction
  factory AppTransaction.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppTransaction(
      id: doc.id,
      title: d['title'] ?? '',
      category: d['category'] ?? 'Otros',
      amount: (d['amount'] as num).toDouble(),
      isIncome: d['isIncome'] ?? false,
      date: (d['date'] as Timestamp).toDate(),
    );
  }

  // Convierte AppTransaction → Firestore
  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'amount': amount,
        'isIncome': isIncome,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      };
}

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

// ─── FIRESTORE SERVICE ─────────────────────────────────────────────────────────

class _TxService {
  final String uid;
  _TxService(this.uid);

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions');

  // Stream en tiempo real
  Stream<List<AppTransaction>> stream() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppTransaction.fromDoc).toList());

  // Agregar
  Future<void> add(AppTransaction tx) => _col.add(tx.toMap());

  // Eliminar
  Future<void> delete(String id) => _col.doc(id).delete();
}

// ─── DASHBOARD SCREEN ──────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();
  late final _TxService _txService;
  late final String _uid;
  late final String _userName;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _uid = user.uid;
    _userName = user.displayName ?? user.email?.split('@').first ?? 'Usuario';
    _txService = _TxService(_uid);
  }

  Future<void> _logout() async {
    //await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _AddTransactionDialog(
        onAdd: (tx) => _txService.add(tx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: StreamBuilder<List<AppTransaction>>(
        stream: _txService.stream(),
        builder: (context, snapshot) {
          // Cargando primera vez
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

          return Column(
            children: [
              _TopBar(
                onNew: _showAddDialog,
                onLogout: _logout,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner bienvenida
                      _WelcomeBanner(name: _userName),
                      const SizedBox(height: 20),
                      // Cards de balance
                      _BalanceCards(
                          balance: balance, income: income, expense: expense),
                      const SizedBox(height: 20),
                      // Gráficos (solo si hay gastos)
                      if (transactions.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _DonutCard(transactions: transactions)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _BudgetBarsCard(
                                    transactions: transactions)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Transacciones
                      _TransactionsCard(
                        transactions: transactions,
                        onDelete: (id) => _txService.delete(id),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── TOP BAR ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onNew;
  final Future<void> Function() onLogout;

  const _TopBar({required this.onNew, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 16,
        bottom: 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: kAmber, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('KyboApp',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: kDark)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva transacción',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAmber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async => await onLogout(),
                icon: const Icon(Icons.logout_rounded, color: kGrey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kAmber, kAmber.withOpacity(0.15)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WELCOME BANNER ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kAmber,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: kAmber.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Bienvenido de nuevo,',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.85))),
                Text('$name! 👋',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Aquí tienes el resumen de tus finanzas.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),
          const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 48),
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
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Balance total',
                value: 'COP ${balance.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: kAmber,
                valueColor: kDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Ingresos',
                value: 'COP ${income.toStringAsFixed(2)}',
                icon: Icons.trending_up_rounded,
                iconColor: kGreen,
                valueColor: kGreen)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Gastos',
                value: 'COP ${expense.toStringAsFixed(2)}',
                icon: Icons.trending_down_rounded,
                iconColor: kRed,
                valueColor: kRed)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor, valueColor;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.iconColor,
      required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(label, style: const TextStyle(fontSize: 12, color: kGrey)),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
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
    // Agrupar gastos por categoría
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

  // Presupuestos fijos de referencia
  static const Map<String, double> _budgets = {
    'Alimentación': 300,
    'Transporte': 150,
    'Entretenimiento': 100,
    'Salud': 200,
    'Educación': 100,
    'Hogar': 1000,
    'Ropa': 100,
    'Servicios': 200,
    'Otros': 100,
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
                          'COP ${spent.toStringAsFixed(0)} / COP ${budget.toStringAsFixed(0)}',
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

  const _TransactionsCard({required this.transactions, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                    Text('Presiona "+ Nueva transacción" para comenzar',
                        style: TextStyle(color: kGrey, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...transactions.asMap().entries.map((e) => Column(
                  children: [
                    _TxRow(tx: e.value, onDelete: () => onDelete(e.value.id)),
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

  const _TxRow({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(tx.category);
    final icon = _catIcon(tx.category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kDark)),
                const SizedBox(height: 2),
                Text('${tx.category} · ${_formatDate(tx.date)}',
                    style: const TextStyle(fontSize: 11, color: kGrey)),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'} COP ${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tx.isIncome ? kGreen : kRed),
          ),
          const SizedBox(width: 8),
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

// ─── ADD TRANSACTION DIALOG ────────────────────────────────────────────────────

class _AddTransactionDialog extends StatefulWidget {
  final Future<void> Function(AppTransaction) onAdd;
  const _AddTransactionDialog({required this.onAdd});

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  bool _isIncome = false;
  bool _loading = false;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  final List<String> _expenseCategories = [
    'Alimentación',
    'Transporte',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Hogar',
    'Ropa',
    'Servicios',
    'Otros',
  ];
  final List<String> _incomeCategories = [
    'Ingreso',
    'Trabajo',
    'Otros',
  ];

  List<String> get _categories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kAmber),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Ingresa una descripción');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Ingresa un monto válido');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Selecciona una categoría');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onAdd(AppTransaction(
        id: '',
        title: _titleCtrl.text.trim(),
        category: _selectedCategory!,
        amount: amount,
        isIncome: _isIncome,
        date: _selectedDate,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: kRed),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Agregar transacción',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: kDark)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: kGrey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Toggle Gasto / Ingreso (igual al screenshot)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isIncome = false;
                        _selectedCategory = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        decoration: BoxDecoration(
                          color: !_isIncome ? kRed : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: !_isIncome ? kRed : Colors.grey[300]!),
                        ),
                        alignment: Alignment.center,
                        child: Text('Gasto',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_isIncome ? Colors.white : kGrey,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isIncome = true;
                        _selectedCategory = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isIncome ? kGreen : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _isIncome ? kGreen : Colors.grey[300]!),
                        ),
                        alignment: Alignment.center,
                        child: Text('Ingreso',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isIncome ? Colors.white : kGrey,
                            )),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Descripción
              const Text('Descripción',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              _Field(
                controller: _titleCtrl,
                hint: 'Ej: Supermercado',
              ),
              const SizedBox(height: 16),

              // Monto
              const Text('Monto',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              _Field(
                controller: _amountCtrl,
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Categoría dropdown
              const Text('Categoría',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('Seleccione una categoría',
                        style: TextStyle(color: kGrey, fontSize: 14)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: kGrey),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: _catColor(cat),
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat,
                                      style: const TextStyle(
                                          fontSize: 14, color: kDark)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha
              const Text('Fecha',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 14, color: kDark)),
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: kGrey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Agregar (verde como en el screenshot)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreenBtn,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Agregar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FIELD HELPER ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _Field(
      {required this.controller, required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kGrey, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kAmber, width: 1.5),
        ),
      ),
    );
  }
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
