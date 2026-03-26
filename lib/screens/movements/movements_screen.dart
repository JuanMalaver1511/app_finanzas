import 'package:flutter/material.dart';

const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color.fromARGB(255, 29, 126, 69);
const kRed = Color(0xFFE74C3C);

class Movement {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isIncome;

  Movement({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  DateTime selectedMonth = DateTime.now();

  final List<Movement> movements = [
    Movement(
      title: "Spotify",
      category: "Entretenimiento",
      amount: 10000,
      date: DateTime.now(),
      isIncome: false,
    ),
    Movement(
      title: "Ropa bebé",
      category: "Ropa",
      amount: 600000,
      date: DateTime.now(),
      isIncome: false,
    ),
    Movement(
      title: "Salario",
      category: "Trabajo",
      amount: 3000000,
      date: DateTime.now(),
      isIncome: true,
    ),
  ];

  List<Movement> get filtered => movements
      .where((m) =>
          m.date.month == selectedMonth.month &&
          m.date.year == selectedMonth.year)
      .toList();

  double get income =>
      filtered.where((m) => m.isIncome).fold(0, (a, b) => a + b.amount);

  double get expense =>
      filtered.where((m) => !m.isIncome).fold(0, (a, b) => a + b.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text(
          "Movimientos",
          style: TextStyle(color: kDark, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: kDark),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _summary(),
                  const SizedBox(height: 20),
                  _movementsList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔹 HEADER (MES + FILTRO)
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${_monthName(selectedMonth.month)} ${selectedMonth.year}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kDark,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: kAmber),
            onPressed: _pickMonth,
          )
        ],
      ),
    );
  }

  /// 🔹 RESUMEN (cards estilo dashboard)
  Widget _summary() {
    return Row(
      children: [
        Expanded(child: _summaryCard("Ingresos", income, kGreen)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard("Gastos", expense, kRed)),
      ],
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kGrey)),
          const SizedBox(height: 6),
          Text(
            "COP ${value.toStringAsFixed(0)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }

  /// 🔹 LISTA
  Widget _movementsList() {
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            "No hay movimientos",
            style: TextStyle(color: kGrey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: filtered.map((m) => _item(m)).toList(),
      ),
    );
  }

  Widget _item(Movement m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (m.isIncome ? kGreen : kRed).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              m.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: m.isIncome ? kGreen : kRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kDark,
                  ),
                ),
                Text(
                  m.category,
                  style: const TextStyle(fontSize: 12, color: kGrey),
                ),
              ],
            ),
          ),
          Text(
            "${m.isIncome ? '+' : '-'} COP ${m.amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: m.isIncome ? kGreen : kRed,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  /// 🔹 FUNCIONES
  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedMonth = picked);
    }
  }

  String _monthName(int m) {
    const months = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre"
    ];
    return months[m - 1];
  }
}
