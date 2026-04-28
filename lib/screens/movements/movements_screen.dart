import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/transaction_model.dart';
import 'package:intl/intl.dart';
import '../../widgets/dashboard/add_transaction_dialog.dart';

// ─── COLORES (mismos que el dashboard) ───────────────────────────────────────
const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF1D7E45);
const kRed = Color(0xFFE74C3C);
const kAmberLight = Color(0xFFFFF3DC);

// ─── DATOS MENSUALES PARA GRÁFICA ────────────────────────────────────────────
class _MonthlyData {
  final String label;
  final double income;
  final double expense;
  _MonthlyData(this.label, this.income, this.expense);
}

// ─────────────────────────────────────────────────────────────────────────────
//  MOVEMENTS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen>
    with TickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  String _selectedTypeFilter = 'all'; // all, expense, income
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  CollectionReference get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions');
  }

  // ── Stream del mes seleccionado ──
  Stream<List<AppTransaction>> get _monthStream {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AppTransaction.fromDoc).toList());
  }

  // ── Stream gráfica últimos 6 meses ──
  Stream<List<_MonthlyData>> get _chartStream {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5);
    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('date')
        .snapshots()
        .map((s) {
      final txs = s.docs.map(AppTransaction.fromDoc).toList();
      final map = <String, _MonthlyData>{};

      for (int i = 5; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i);
        map['${m.year}-${m.month}'] = _MonthlyData(_monthShort(m.month), 0, 0);
      }

      for (final t in txs) {
        final k = '${t.date.year}-${t.date.month}';
        if (map.containsKey(k)) {
          final o = map[k]!;
          map[k] = _MonthlyData(
            o.label,
            o.income + (t.isIncome ? t.amount : 0),
            o.expense + (!t.isIncome ? t.amount : 0),
          );
        }
      }

      return map.values.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _loadCategories();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _selectedCategory = null;
      _selectedTypeFilter = 'all';
      _fadeCtrl
        ..reset()
        ..forward();
    });
  }

  Future<void> _loadCategories() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final globalSnap =
        await FirebaseFirestore.instance.collection('categories').get();

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('categories')
        .get();

    final global = globalSnap.docs.map((d) => {
          ...d.data(),
          'id': d.id,
        });

    final user = userSnap.docs.map((d) => {
          ...d.data(),
          'id': d.id,
        });

    final merged = [...global, ...user];

    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];

    for (final cat in merged) {
      final name = (cat['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final key = name.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(cat);
      }
    }

    unique.sort((a, b) {
      final aName = (a['name'] ?? '').toString().toLowerCase();
      final bName = (b['name'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });

    if (!mounted) return;

    setState(() {
      _categories = unique;

      final stillExists = _selectedCategory == null ||
          unique.any(
              (cat) => (cat['name'] ?? '').toString() == _selectedCategory);

      if (!stillExists) {
        _selectedCategory = null;
        _selectedTypeFilter = 'all';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final isDesktop = constraints.maxWidth >= 1024;

                if (isDesktop) {
                  return _buildDesktopLayout();
                }

                return _buildMobileLayout(isMobile);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isMobile) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(isMobile),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 8,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMonthSelector(),
              const SizedBox(height: 16),
              StreamBuilder<List<AppTransaction>>(
                stream: _monthStream,
                builder: (_, snap) {
                  final list = snap.data ?? [];
                  final income = list
                      .where((t) => t.isIncome)
                      .fold(0.0, (a, b) => a + b.amount);
                  final expense = list
                      .where((t) => !t.isIncome)
                      .fold(0.0, (a, b) => a + b.amount);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(income, expense, isMobile),
                      const SizedBox(height: 14),
                      _buildSummaryCards(income, expense, isMobile, list),
                      const SizedBox(height: 14),
                      _movementInsightStrip(
                        expense: expense,
                        transactions: list,
                      ),
                      const SizedBox(height: 20),
                      _buildChartSection(),
                      const SizedBox(height: 20),
                      _buildCategoryFilter(),
                      const SizedBox(height: 16),
                      _buildTransactionList(list, snap.connectionState),
                      const SizedBox(height: 90),
                    ],
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _movementInsightStrip({
    required double expense,
    required List<AppTransaction> transactions,
  }) {
    final topCategory = _topExpenseCategory(transactions);

    final avgDailyExpense = _averageDailyExpense(expense);
    final projectedExpense = _projectedMonthExpense(expense);
    final mostExpensiveDay = _mostExpensiveDay(transactions);

    return FutureBuilder<double>(
      future: _previousMonthExpenseTotal(),
      builder: (context, snapshot) {
        final previousExpense = snapshot.data ?? 0;

        String comparisonText = 'Sin comparación del mes anterior';
        Color comparisonColor = kGrey;
        IconData comparisonIcon = Icons.remove_rounded;

        if (previousExpense > 0) {
          final diffPercent =
              ((expense - previousExpense) / previousExpense) * 100;
          final isHigher = diffPercent > 0;

          comparisonText =
              '${isHigher ? '+' : ''}${diffPercent.toStringAsFixed(0)}% vs mes pasado';
          comparisonColor = isHigher ? kRed : kGreen;
          comparisonIcon = isHigher
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Análisis inteligente',
                style: TextStyle(
                  color: kDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lectura rápida de tus gastos del mes.',
                style: TextStyle(
                  color: kGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _insightBadge(
                    icon: comparisonIcon,
                    text: comparisonText,
                    color: comparisonColor,
                  ),
                  if (topCategory != null)
                    _insightBadge(
                      icon: Icons.category_rounded,
                      text: 'Mayor gasto: $topCategory',
                      color: kAmber,
                    ),
                  if (expense > 0)
                    _insightBadge(
                      icon: Icons.calendar_today_rounded,
                      text: 'Promedio diario: ${_formatCOP(avgDailyExpense)}',
                      color: kDark,
                    ),
                  if (projectedExpense > expense)
                    _insightBadge(
                      icon: Icons.insights_rounded,
                      text: 'Proyección: ${_formatCOP(projectedExpense)}',
                      color: projectedExpense > expense * 1.25 ? kRed : kAmber,
                    ),
                  if (mostExpensiveDay != null)
                    _insightBadge(
                      icon: Icons.local_fire_department_rounded,
                      text: 'Día más alto: $mostExpensiveDay',
                      color: kRed,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _insightBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (color == kRed) {
      bgColor = const Color(0xFFFFE3E0);
      borderColor = const Color(0xFFFF8A80);
      textColor = const Color(0xFFC62828);
    } else if (color == kAmber) {
      bgColor = const Color(0xFFFFE6B8);
      borderColor = const Color(0xFFFFB84E);
      textColor = const Color(0xFF8A4F00);
    } else if (color == kGreen) {
      bgColor = const Color(0xFFDDF7E8);
      borderColor = const Color(0xFF7ED9A5);
      textColor = const Color(0xFF145C35);
    } else {
      bgColor = const Color(0xFFE9ECF2);
      borderColor = const Color(0xFFC8CED8);
      textColor = const Color(0xFF2B2F3A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String? _topExpenseCategory(List<AppTransaction> transactions) {
    final totals = <String, double>{};

    for (final tx in transactions) {
      if (tx.isIncome) continue;

      final category =
          tx.category.trim().isEmpty ? 'Otros' : tx.category.trim();

      totals[category] = (totals[category] ?? 0) + tx.amount;
    }

    if (totals.isEmpty) return null;

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  double _averageDailyExpense(double expense) {
    final totalDays = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    if (totalDays == 0) return 0;
    return expense / totalDays;
  }

  double _projectedMonthExpense(double expense) {
    final now = DateTime.now();

    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    if (!isCurrentMonth || expense <= 0) return expense;

    final currentDay = now.day;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    return (expense / currentDay) * totalDays;
  }

  String? _mostExpensiveDay(List<AppTransaction> transactions) {
    final totals = <String, double>{};

    for (final tx in transactions) {
      if (tx.isIncome) continue;

      final label = '${tx.date.day} de ${_monthName(tx.date.month)}';
      totals[label] = (totals[label] ?? 0) + tx.amount;
    }

    if (totals.isEmpty) return null;

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  AppTransaction? _highestTransaction(List<AppTransaction> list) {
    final expenses = list.where((t) => !t.isIncome).toList();

    if (expenses.isEmpty) return null;

    expenses.sort((a, b) => b.amount.compareTo(a.amount));

    return expenses.first;
  }

  Future<double> _previousMonthExpenseTotal() async {
    final previousMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    );

    final start = DateTime(previousMonth.year, previousMonth.month);
    final end = DateTime(previousMonth.year, previousMonth.month + 1);

    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    double total = 0;

    for (final doc in snap.docs) {
      final tx = AppTransaction.fromDoc(doc);
      if (!tx.isIncome) {
        total += tx.amount;
      }
    }

    return total;
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildDesktopHeader(),
        Expanded(
          child: StreamBuilder<List<AppTransaction>>(
            stream: _monthStream,
            builder: (_, snap) {
              final list = snap.data ?? [];
              final income = list
                  .where((t) => t.isIncome)
                  .fold(0.0, (a, b) => a + b.amount);
              final expense = list
                  .where((t) => !t.isIncome)
                  .fold(0.0, (a, b) => a + b.amount);

              return LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = 20.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        horizontalPadding, 8, horizontalPadding, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildMonthSelector(),
                                const SizedBox(height: 16),
                                _buildHeroCard(income, expense, false),
                                const SizedBox(height: 14),
                                _buildSummaryCards(
                                    income, expense, false, list),
                                const SizedBox(height: 14),
                                _movementInsightStrip(
                                  expense: expense,
                                  transactions: list,
                                ),
                                const SizedBox(height: 20),
                                _buildChartSection(),
                                const SizedBox(height: 90),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildCategoryFilter(),
                              const SizedBox(height: 16),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _buildTransactionList(
                                        list,
                                        snap.connectionState,
                                      ),
                                      const SizedBox(height: 90),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kDark.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: kDark, size: 20),
      ),
    );
  }

  Widget _headerActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: kAmber,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kAmber.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kDark.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: kAmber,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Mis movimientos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: kDark,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          _headerIconButton(
            icon: Icons.help_outline_rounded,
            onTap: _showHelpDialog,
          ),
          const SizedBox(width: 10),
          _headerActionButton(
            label: 'Nueva transacción',
            icon: Icons.add_rounded,
            onTap: _openAddTransaction,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return SliverAppBar(
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: isMobile ? 72 : 78,
      titleSpacing: isMobile ? 14 : 20,
      title: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kDark.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: kAmber,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mis movimientos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: kDark,
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 17 : 22,
              ),
            ),
          ),
          _headerIconButton(
            icon: Icons.help_outline_rounded,
            onTap: _showHelpDialog,
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _openAddTransaction,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: kAmber,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kAmber.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Nueva",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final canGoNext = _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, () => _changeMonth(-1)),
          Expanded(
            child: GestureDetector(
              onTap: _pickMonth,
              child: Column(
                children: [
                  Text(
                    _monthName(_selectedMonth.month),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${_selectedMonth.year}',
                    style: const TextStyle(fontSize: 12, color: kGrey),
                  ),
                ],
              ),
            ),
          ),
          _navBtn(
            Icons.chevron_right_rounded,
            canGoNext ? () => _changeMonth(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null ? kBg.withOpacity(0.5) : kBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: onTap == null ? kGrey.withOpacity(0.4) : kDark,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildHeroCard(double income, double expense, bool isMobile) {
    final balance = income - expense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance del mes',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCOP(balance.abs()),
                style: TextStyle(
                  color: balance >= 0 ? const Color(0xFF56E39F) : kRed,
                  fontSize: isMobile ? 30 : 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                balance >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: balance >= 0 ? const Color(0xFF56E39F) : kRed,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            balance >= 0 ? 'Vas bien 👍' : 'Revisa tus gastos',
            style: TextStyle(
              color: balance >= 0 ? const Color(0xFF56E39F) : kRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    double income,
    double expense,
    bool isMobile,
    List<AppTransaction> transactions,
  ) {
    final balance = income - expense;

    final statusColor = balance >= 0 ? kGreen : kRed;
    final statusTitle = balance >= 0 ? 'Balance positivo' : 'Balance negativo';
    final statusMessage = balance >= 0
        ? 'Tus ingresos cubren tus gastos este mes.'
        : 'Tus gastos superan tus ingresos registrados.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  balance >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        color: kDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        color: kGrey,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFinancialHealthCard(income, expense),
          const SizedBox(height: 16),
          if (isMobile) ...[
            _movementMetricCard(
              title: 'Ingresos',
              value: _formatCOP(income),
              icon: Icons.south_rounded,
              color: kGreen,
            ),
            const SizedBox(height: 10),
            _movementMetricCard(
              title: 'Gastos',
              value: _formatCOP(expense),
              icon: Icons.north_rounded,
              color: kRed,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _movementMetricCard(
                    title: 'Ingresos',
                    value: _formatCOP(income),
                    icon: Icons.south_rounded,
                    color: kGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _movementMetricCard(
                    title: 'Gastos',
                    value: _formatCOP(expense),
                    icon: Icons.north_rounded,
                    color: kRed,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard(double income, double expense) {
    final score = _financialHealthScore(income, expense);

    Color color;
    String title;
    String message;

    if (score >= 80) {
      color = kGreen;
      title = 'Salud financiera alta';
      message = 'Buen control este mes. Estás gastando con equilibrio.';
    } else if (score >= 55) {
      color = kAmber;
      title = 'Salud financiera media';
      message = 'Vas bien, pero puedes cuidar un poco más tus gastos.';
    } else {
      color = kRed;
      title = 'Salud financiera baja';
      message = 'Tus gastos están muy cerca o por encima de tus ingresos.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.14),
                  color: color,
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _financialHealthScore(double income, double expense) {
    if (income <= 0 && expense <= 0) return 0;
    if (income <= 0 && expense > 0) return 20;

    final balance = income - expense;
    final savingRate = balance / income;

    if (savingRate >= 0.35) return 95;
    if (savingRate >= 0.25) return 88;
    if (savingRate >= 0.15) return 78;
    if (savingRate >= 0.05) return 65;
    if (savingRate >= 0) return 55;
    if (savingRate >= -0.10) return 38;

    return 20;
  }

  Widget _movementMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFEAECEF)),
      );

  Widget _miniCard(String title, double value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCOP(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimos 6 meses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kDark,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  _legend(kGreen, 'Ingresos'),
                  const SizedBox(width: 12),
                  _legend(kRed, 'Gastos'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<_MonthlyData>>(
            stream: _chartStream,
            builder: (_, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: kAmber,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 160,
                child: _BarChart(data: snap.data!),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: kGrey)),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'Todos',
            active: _selectedTypeFilter == 'all' && _selectedCategory == null,
            onTap: () {
              setState(() {
                _selectedTypeFilter = 'all';
                _selectedCategory = null;
              });
            },
          ),
          const SizedBox(width: 10),
          _filterChip(
            label: 'Gastos',
            active: _selectedTypeFilter == 'expense',
            onTap: () {
              setState(() {
                _selectedTypeFilter = 'expense';
              });
            },
          ),
          const SizedBox(width: 10),
          _filterChip(
            label: 'Ingresos',
            active: _selectedTypeFilter == 'income',
            onTap: () {
              setState(() {
                _selectedTypeFilter = 'income';
              });
            },
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showCategoryModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedCategory ?? "Categorías",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kAmber : kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? kAmber : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? kDark : kGrey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showCategoryModal() async {
    await _loadCategories();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 400,
            child: ListView(
              children: [
                const Text(
                  "Categorías",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text("Todos"),
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedTypeFilter = 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
                ..._categories.map((cat) {
                  return ListTile(
                    title: Text(cat['name']),
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['name'];
                        _selectedTypeFilter = 'all';
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(
    List<AppTransaction> all,
    ConnectionState state,
  ) {
    List<AppTransaction> list = _selectedCategory == null
        ? List<AppTransaction>.from(all)
        : all.where((t) => t.category == _selectedCategory).toList();

    if (_selectedTypeFilter == 'expense') {
      list = list.where((t) => !t.isIncome).toList();
    } else if (_selectedTypeFilter == 'income') {
      list = list.where((t) => t.isIncome).toList();
    }

    if (state == ConnectionState.waiting && all.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: kAmber, strokeWidth: 2),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kAmberLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: kAmber,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin transacciones',
                style: TextStyle(
                  color: kDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedCategory != null
                    ? 'No hay movimientos para la categoría seleccionada'
                    : _selectedTypeFilter == 'expense'
                        ? 'No hay gastos en este período'
                        : _selectedTypeFilter == 'income'
                            ? 'No hay ingresos en este período'
                            : 'No hay registros para este período',
                style: const TextStyle(color: kGrey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<AppTransaction>>{};
    for (final t in list) {
      grouped.putIfAbsent(_dateLabel(t.date), () => []).add(t);
    }

    final highestTransaction = _highestTransaction(list);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((e) {
        final gastos = e.value.where((t) => !t.isIncome).toList();
        final ingresos = e.value.where((t) => t.isIncome).toList();

        gastos.sort((a, b) => b.amount.compareTo(a.amount));
        ingresos.sort((a, b) => b.amount.compareTo(a.amount));

        final totalGastos = gastos.fold<double>(0, (sum, t) => sum + t.amount);
        final totalIngresos =
            ingresos.fold<double>(0, (sum, t) => sum + t.amount);

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kDark.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: kGrey,
                ),
              ),
              const SizedBox(height: 10),
              if (gastos.isNotEmpty) ...[
                _sectionHeader('Gastos', kRed, totalGastos),
                ...gastos.map(
                  (t) => _transactionTile(
                    t,
                    isTop: highestTransaction != null &&
                        t.id == highestTransaction.id,
                  ),
                ),
              ],
              if (gastos.isNotEmpty && ingresos.isNotEmpty)
                const SizedBox(height: 10),
              if (ingresos.isNotEmpty) ...[
                _sectionHeader('Ingresos', kGreen, totalIngresos),
                ...ingresos.map((t) => _transactionTile(t)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionHeader(String text, Color color, double total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatCOP(total),
            style: const TextStyle(
              color: kGrey,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(AppTransaction t, {bool isTop = false}) {
    final color = t.isIncome ? kGreen : kRed;
    final softColor = color.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isTop ? kAmber : kBg,
          width: isTop ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kDark.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _showDetail(t),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      t.emoji.isNotEmpty ? t.emoji : '💰',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: softColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t.isIncome ? 'Ingreso' : 'Gasto',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isTop)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kAmber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Gasto más alto',
                              style: TextStyle(
                                color: kAmber,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${t.isIncome ? '+' : '-'} ${_formatCOP(t.amount)}',
                            style: TextStyle(
                              color: color,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeStr(t.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: kGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: kGrey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditTransaction(t);
                    } else if (value == 'delete') {
                      _confirmDelete(t);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: kRed,
                          ),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(AppTransaction t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(transaction: t),
    );
  }

  Future<void> _confirmDelete(AppTransaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar transacción',
          style: TextStyle(fontWeight: FontWeight.w700, color: kDark),
        ),
        content: Text(
          '¿Eliminar "${t.title}"?',
          style: const TextStyle(color: kGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: kGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _col.doc(t.id).delete();
    }
  }

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar mes',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kAmber,
            onPrimary: kDark,
            onSurface: kDark,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _selectedCategory = null;
        _selectedTypeFilter = 'all';
      });
    }
  }

  void _openAddTransaction() async {
    await showDialog(
      context: context,
      builder: (_) => AddTransactionDialog(
        onAdd: (tx) async {
          await _col.add(tx.toMap());
        },
      ),
    );

    if (!mounted) return;
    await _loadCategories();
  }

  void _openEditTransaction(AppTransaction tx) async {
    await showDialog(
      context: context,
      builder: (_) => AddTransactionDialog(
        initial: tx,
        onAdd: (updatedTx) async {
          await _col.doc(tx.id).update(updatedTx.toMap());
        },
      ),
    );

    if (!mounted) return;
    await _loadCategories();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: kAmber.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: kAmber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Guía rápida de movimientos',
                        style: TextStyle(
                          color: kDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _helpItem(
                  icon: Icons.add_circle_outline_rounded,
                  title: '1. Registra ingresos y gastos',
                  description:
                      'Usa el botón Nueva para guardar cada movimiento y mantener tu balance actualizado.',
                ),
                _helpItem(
                  icon: Icons.filter_alt_outlined,
                  title: '2. Filtra tus movimientos',
                  description:
                      'Puedes revisar todos, solo gastos, solo ingresos o una categoría específica.',
                ),
                _helpItem(
                  icon: Icons.insights_rounded,
                  title: '3. Revisa el análisis inteligente',
                  description:
                      'Kybo te muestra tu mayor gasto, promedio diario, proyección mensual y el día con más gastos.',
                ),
                _helpItem(
                  icon: Icons.star_border_rounded,
                  title: '4. Identifica tu gasto más alto',
                  description:
                      'El movimiento más fuerte del mes se marca para que sepas dónde poner atención.',
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kAmber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '💡 Tip: registra tus movimientos el mismo día para que las proyecciones sean más precisas.',
                    style: TextStyle(
                      color: kDark,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAmber,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kDark, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCOP(double value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return 'HOY';
    }
    return '${d.day} de ${_monthName(d.month)}';
  }

  String _timeStr(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _monthName(int m) => const [
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
      ][m - 1];

  String _monthShort(int m) => const [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ][m - 1];
}

// ─── GRÁFICA DE BARRAS ────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<_MonthlyData> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        data.fold(0.0, (p, e) => math.max(p, math.max(e.income, e.expense)));

    if (maxVal == 0) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: kGrey)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data
          .map(
            (d) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _AnimBar(value: d.income, max: maxVal, color: kGreen),
                        const SizedBox(width: 3),
                        _AnimBar(value: d.expense, max: maxVal, color: kRed),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AnimBar extends StatelessWidget {
  final double value;
  final double max;
  final Color color;

  const _AnimBar({
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final h = max > 0 ? (value / max) * 110 : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: h),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Container(
        width: 12,
        height: math.max(v, 3),
        decoration: BoxDecoration(
          color: v < 4 ? color.withOpacity(0.2) : color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

// ─── SHEET DETALLE ────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final AppTransaction transaction;

  const _DetailSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final color = t.isIncome ? kGreen : kRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                t.emoji.isNotEmpty ? t.emoji : '💰',
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${t.isIncome ? '+' : '-'} COP ${t.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          _row('Categoría', t.category),
          _row('Tipo', t.isIncome ? 'Ingreso' : 'Gasto'),
          _row(
            'Fecha',
            '${t.date.day.toString().padLeft(2, '0')}/'
                '${t.date.month.toString().padLeft(2, '0')}/'
                '${t.date.year}',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kGrey)),
          Text(
            value,
            style: const TextStyle(
              color: kDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
