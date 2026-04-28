import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const kPrimary = Color(0xFF2B2257);
const kAccent = Color(0xFFFFB84E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF27AE60);
const kRed = Color(0xFFE74C3C);
const kBlue = Color(0xFF6366F1);

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ReportsScreen({super.key, this.onBack});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int selectedTab = 0;
  DateTime selectedDate = DateTime.now();

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DateTime get _startDate {
    if (selectedTab == 0) {
      final start =
          selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      return DateTime(start.year, start.month, start.day);
    }
    return DateTime(selectedDate.year, selectedDate.month, 1);
  }

  DateTime get _endDate {
    if (selectedTab == 0) return _startDate.add(const Duration(days: 7));
    return DateTime(selectedDate.year, selectedDate.month + 1, 1);
  }

  String get _periodLabel {
    if (selectedTab == 0) {
      final end = _startDate.add(const Duration(days: 6));
      return '${_shortDate(_startDate)} - ${_shortDate(end)}';
    }
    return '${_monthName(selectedDate.month)} ${selectedDate.year}';
  }

  void _previousPeriod() {
    setState(() {
      selectedDate = selectedTab == 0
          ? selectedDate.subtract(const Duration(days: 7))
          : DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void _nextPeriod() {
    setState(() {
      selectedDate = selectedTab == 0
          ? selectedDate.add(const Duration(days: 7))
          : DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  void _changeTab(int index) {
    setState(() {
      selectedTab = index;
      selectedDate = DateTime.now();
    });
  }

  String _shortDate(DateTime date) => '${date.day} ${_shortMonth(date.month)}';

  String _shortMonth(int month) {
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
      'dic'
    ];
    return months[month - 1];
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _tabs(),
            _periodSelector(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .collection('budgets')
                    .doc(DateFormat('yyyy-MM').format(selectedDate))
                    .collection('items')
                    .snapshots(),
                builder: (context, budgetSnapshot) {
                  if (budgetSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kAccent),
                    );
                  }

                  final budgetDocs = budgetSnapshot.data?.docs ?? [];

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_uid)
                        .collection('transactions')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: kAccent),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final report = _buildReport(docs, budgetDocs);

                      return Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: false,
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _financialScore(report),
                            const SizedBox(height: 16),
                            if (selectedTab == 1) ...[
                              _budgetSummaryCard(report),
                              const SizedBox(height: 16),
                              _budgetCategoriesCard(report),
                              const SizedBox(height: 16),
                            ],
                            _barChartCard(report),
                            const SizedBox(height: 16),
                            _donutCard(report),
                            const SizedBox(height: 16),
                            _lineChartCard(report),
                            const SizedBox(height: 16),
                            _insightsCard(report),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ReportData _buildReport(
    List<QueryDocumentSnapshot> docs,
    List<QueryDocumentSnapshot> budgetDocs,
  ) {
    double income = 0;
    double expense = 0;

    final Map<String, double> categoryTotals = {};
    final Map<String, String> categoryNames = {};
    final Map<String, double> budgetMap = {};
    final int slots = selectedTab == 0 ? 7 : 5;
    final List<double> periodValues = List.filled(slots, 0);

    for (final doc in budgetDocs) {
      final data = doc.data() as Map<String, dynamic>;

      final key = (data['categoryKey'] ?? '').toString().trim().toLowerCase();
      final planned = _toDouble(data['planned']);

      if (key.isNotEmpty) {
        budgetMap[key] = planned;
      }
    }

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final amount = _toDouble(data['amount']);
      final isIncome = data['isIncome'] == true;
      final date = _toDate(data['date']);

      if (date == null) continue;
      if (date.isBefore(_startDate) || !date.isBefore(_endDate)) continue;

      if (isIncome) {
        income += amount;
      } else {
        expense += amount;

        final categoryName =
            (data['categoryName'] ?? data['category'] ?? 'Otros')
                .toString()
                .trim();

        final categoryKey = categoryName.toLowerCase();

        categoryTotals[categoryKey] =
            (categoryTotals[categoryKey] ?? 0) + amount;
        categoryNames[categoryKey] = categoryName;

        if (selectedTab == 0) {
          final index = date.weekday - 1;
          if (index >= 0 && index < 7) periodValues[index] += amount;
        } else {
          final weekIndex = ((date.day - 1) / 7).floor().clamp(0, 4);
          periodValues[weekIndex] += amount;
        }
      }
    }

    final allBudgetKeys = {
      ...budgetMap.keys,
      ...categoryTotals.keys,
    };

    final budgetCategories = allBudgetKeys.map((key) {
      return _BudgetCategoryData(
        name: categoryNames[key] ?? key,
        planned: budgetMap[key] ?? 0,
        spent: categoryTotals[key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    final totalBudget =
        budgetCategories.fold<double>(0, (sum, item) => sum + item.planned);
    final budgetRemaining = totalBudget - expense;
    final budgetUsedPercent = totalBudget <= 0 ? 0.0 : expense / totalBudget;

    final balance = income - expense;
    final score = _calculateScore(income, expense, balance);
    final sortedCategories = categoryTotals.entries
        .map(
          (entry) => MapEntry(
            categoryNames[entry.key] ?? entry.key,
            entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ReportData(
      income: income,
      expense: expense,
      balance: balance,
      score: score,
      categories: sortedCategories,
      periodValues: periodValues,
      totalBudget: totalBudget,
      budgetUsedPercent: budgetUsedPercent,
      budgetRemaining: budgetRemaining,
      budgetCategories: budgetCategories,
    );
  }

  int _calculateScore(double income, double expense, double balance) {
    int score = 50;
    if (income > 0) score += 15;
    if (balance >= 0) score += 20;
    if (income > 0 && expense <= income * 0.7) score += 15;
    if (income > 0 && expense > income) score -= 25;
    if (income <= 0 && expense > 0) score -= 20;
    return score.clamp(0, 100);
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _money(double value, {bool compact = true}) {
    if (compact) {
      if (value.abs() >= 1000000)
        return '\$${(value / 1000000).toStringAsFixed(1)}M';
      if (value.abs() >= 1000) return '\$${(value / 1000).toStringAsFixed(0)}K';
    }

    final f =
        NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return f.format(value);
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onBack ?? () => Navigator.pop(context),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: kPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reportes',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: kDark)),
                SizedBox(height: 2),
                Text('Analiza tus finanzas con claridad',
                    style: TextStyle(
                        color: kGrey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Row(
          children: [
            _tabButton('Semanal', 0, Icons.calendar_view_week_rounded),
            _tabButton('Mensual', 1, Icons.calendar_month_rounded),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String text, int index, IconData icon) {
    final isActive = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: isActive ? Colors.white : kPrimary),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : kPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Row(
          children: [
            _periodButton(Icons.chevron_left_rounded, _previousPeriod),
            Expanded(
              child: Column(
                children: [
                  Text(
                    selectedTab == 0
                        ? 'Semana seleccionada'
                        : 'Mes seleccionado',
                    style: const TextStyle(
                        color: kGrey,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _periodLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: kDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            _periodButton(Icons.chevron_right_rounded, _nextPeriod),
          ],
        ),
      ),
    );
  }

  Widget _periodButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: kPrimary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child:
            SizedBox(width: 40, height: 40, child: Icon(icon, color: kPrimary)),
      ),
    );
  }

  Widget _financialScore(_ReportData report) {
    final isGood = report.score >= 70;
    final isMedium = report.score >= 45 && report.score < 70;
    final color = isGood
        ? kGreen
        : isMedium
            ? kAccent
            : kRed;

    final title = isGood
        ? 'Buen control financiero'
        : isMedium
            ? 'Atención con tus gastos'
            : 'Revisa tus finanzas';

    final message = isGood
        ? 'Tus gastos están equilibrados con tus ingresos.'
        : isMedium
            ? 'Hay margen para mejorar tu balance.'
            : 'Tus gastos están superando tu capacidad actual.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.trending_up_rounded, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: kDark)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        color: kGrey, fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
          Text('${report.score}/100',
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _budgetSummaryCard(_ReportData report) {
    final percent = report.budgetUsedPercent;
    final exceeded = percent > 1;

    final color = exceeded
        ? kRed
        : percent >= 0.85
            ? kAccent
            : kGreen;

    return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: percent > 1 ? 1 : percent,
              color: color,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            if (percent > 1)
              Text(
                'Excedido en ${_money(report.budgetRemaining.abs(), compact: false)}',
                style: const TextStyle(
                  color: kRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ));
  }

  Widget _budgetCategoriesCard(_ReportData report) {
    if (report.budgetCategories.isEmpty) {
      return _emptyReportCard(
          title: 'Presupuesto por categoría', message: 'Sin datos aún');
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Presupuesto por categoría',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 16),
          ...report.budgetCategories.map((item) {
            final percent = item.percent.clamp(0, 1).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percent,
                    color: item.exceeded ? kRed : kGreen,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gastado: ${_money(item.spent, compact: false)} / Presupuestado: ${_money(item.planned, compact: false)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _barChartCard(_ReportData report) {
    final maxValue = [report.income, report.expense, report.balance.abs(), 1.0]
        .reduce((a, b) => a > b ? a : b);

    return _chartCard(
      title: 'Ingresos vs Gastos',
      subtitle:
          selectedTab == 0 ? 'Comparativo semanal' : 'Comparativo mensual',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(report.income, maxValue, kGreen, 'Ingresos'),
          _bar(report.expense, maxValue, kRed, 'Gastos'),
          _bar(report.balance.abs(), maxValue, kAccent, 'Balance'),
        ],
      ),
    );
  }

  Widget _bar(double amount, double maxValue, Color color, String label) {
    final height = maxValue <= 0 ? 8.0 : 24 + ((amount / maxValue) * 96);

    return Column(
      children: [
        Text(_money(amount),
            style: const TextStyle(
                color: kDark, fontSize: 11.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: height,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, color: kGrey, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _donutCard(_ReportData report) {
    if (report.categories.isEmpty) {
      return _emptyReportCard(
          title: 'Gastos por categoría',
          message: 'Aún no hay gastos registrados en este periodo.');
    }

    final total = report.expense <= 0 ? 1.0 : report.expense;
    final colors = [kPrimary, kGreen, kAccent, kRed, kBlue];

    return _chartCard(
      title: 'Gastos por categoría',
      subtitle: 'Distribución principal',
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 135,
            height: 135,
            child: CustomPaint(
              painter: _DonutReportPainter(
                values: report.categories.map((e) => e.value / total).toList(),
                colors: colors,
              ),
              child: const Center(
                child: Text('100%',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, color: kDark)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...report.categories.take(5).toList().asMap().entries.map((entry) {
            final item = entry.value;
            final percent = total > 0 ? (item.value / total * 100).round() : 0;
            return _categoryRow(
                item.key, '$percent%', colors[entry.key % colors.length]);
          }),
        ],
      ),
    );
  }

  Widget _categoryRow(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: kDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5))),
          Text(percent,
              style: const TextStyle(
                  color: kGrey, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _lineChartCard(_ReportData report) {
    final maxValue = report.periodValues.isEmpty
        ? 1.0
        : report.periodValues.reduce((a, b) => a > b ? a : b);
    final normalized = report.periodValues
        .map((value) => maxValue <= 0 ? 0.0 : value / maxValue)
        .toList();
    final maxIndex = report.periodValues.isEmpty
        ? 0
        : report.periodValues.indexWhere((v) => v == maxValue);

    return _chartCard(
      title: selectedTab == 0 ? 'Gastos por día' : 'Gastos por semana',
      subtitle: selectedTab == 0
          ? 'Comportamiento durante la semana'
          : 'Comportamiento durante el mes',
      child: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 120,
            child: CustomPaint(
                painter: _MiniLinePainter(values: normalized),
                size: Size.infinite),
          ),
          const SizedBox(height: 12),
          Text(
            maxValue <= 0
                ? 'No hay gastos registrados en este periodo.'
                : selectedTab == 0
                    ? 'El día con mayor gasto fue ${_dayName(maxIndex)}.'
                    : 'La semana ${maxIndex + 1} tuvo el gasto más alto.',
            style: const TextStyle(
                color: kGrey, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _dayName(int index) {
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];
    if (index < 0 || index >= days.length) return 'un día de la semana';
    return days[index];
  }

  Widget _insightsCard(_ReportData report) {
    final topCategory =
        report.categories.isNotEmpty ? report.categories.first.key : null;

    final insights = <String>[
      if (topCategory != null) 'Tu mayor gasto fue en $topCategory.',
      if (report.balance >= 0)
        'Cerraste este periodo con balance positivo.'
      else
        'Tus gastos superaron tus ingresos en este periodo.',
      if (report.expense > 0)
        'Mantén tus gastos bajo control para mejorar tu score financiero.',
      if (report.expense == 0 && report.income == 0)
        'Aún no tienes movimientos registrados para este periodo.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Insights KYBO',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: kDark, fontSize: 15)),
          const SizedBox(height: 12),
          ...insights.map((text) => _insight(text, Icons.lightbulb_rounded)),
        ],
      ),
    );
  }

  Widget _insight(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: kAccent, size: 19),
          const SizedBox(width: 9),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: kDark,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w600,
                      height: 1.3))),
        ],
      ),
    );
  }

  Widget _emptyReportCard({required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, color: kDark)),
          const SizedBox(height: 14),
          Icon(Icons.insert_chart_outlined_rounded,
              color: kGrey.withOpacity(0.8), size: 38),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kGrey, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _chartCard(
      {required String title,
      required String subtitle,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: kDark, fontSize: 15)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(
                  color: kGrey, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          child,
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
              offset: const Offset(0, 6)),
        ],
        border: Border.all(color: const Color(0xFFEAECEF)),
      );
}

class _ReportData {
  final double income;
  final double expense;
  final double balance;
  final int score;
  final List<MapEntry<String, double>> categories;
  final List<double> periodValues;
  final double totalBudget;
  final double budgetUsedPercent;
  final double budgetRemaining;
  final List<_BudgetCategoryData> budgetCategories;

  const _ReportData({
    required this.income,
    required this.expense,
    required this.balance,
    required this.score,
    required this.categories,
    required this.periodValues,
    required this.totalBudget,
    required this.budgetUsedPercent,
    required this.budgetRemaining,
    required this.budgetCategories,
  });
}

class _BudgetCategoryData {
  final String name;
  final double planned;
  final double spent;

  const _BudgetCategoryData({
    required this.name,
    required this.planned,
    required this.spent,
  });

  double get remaining => planned - spent;

  double get percent {
    if (planned <= 0) return 0;
    return (spent / planned).clamp(0, 999).toDouble();
  }

  bool get exceeded => spent > planned;
}

class _DonutReportPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutReportPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const stroke = 26.0;
    double start = -3.1416 / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * 3.1416 * values[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep - 0.035,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutReportPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _MiniLinePainter extends CustomPainter {
  final List<double> values;

  _MiniLinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFEAECEF)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x =
          values.length == 1 ? 0.0 : size.width * (i / (values.length - 1));
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = kAccent;

    for (final point in points) {
      canvas.drawCircle(point, 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
