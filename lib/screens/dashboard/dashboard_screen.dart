import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

// ── Models ───────────────────────────────────────────────────────────────────

class Transaction {
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final IconData icon;

  Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.icon,
  });
}

class Category {
  final String name;
  final double amount;
  final double budget;
  final Color color;
  final double percentage;

  Category({
    required this.name,
    required this.amount,
    required this.budget,
    required this.color,
    required this.percentage,
  });
}

// ── Data ─────────────────────────────────────────────────────────────────────

final List<Category> categories = [
  Category(
      name: 'Hogar',
      amount: 900,
      budget: 1000,
      color: Color(0xFF4A9B8E),
      percentage: 0.65),
  Category(
      name: 'Alimentación',
      amount: 165,
      budget: 300,
      color: Color(0xFF5BB85D),
      percentage: 0.12),
  Category(
      name: 'Servicios',
      amount: 95,
      budget: 200,
      color: Color(0xFF5BA0D0),
      percentage: 0.07),
  Category(
      name: 'Transporte',
      amount: 85,
      budget: 150,
      color: Color(0xFF3B6FBF),
      percentage: 0.06),
  Category(
      name: 'Salud',
      amount: 80,
      budget: 200,
      color: Color(0xFF9B5BB8),
      percentage: 0.06),
  Category(
      name: 'Educación',
      amount: 50,
      budget: 100,
      color: Color(0xFFD4A017),
      percentage: 0.04),
  Category(
      name: 'Entretenimiento',
      amount: 15,
      budget: 100,
      color: Color(0xFFE05C5C),
      percentage: 0.01),
  Category(
      name: 'Ropa',
      amount: 0,
      budget: 100,
      color: Color(0xFFB85B8A),
      percentage: 0.0),
  Category(
      name: 'Otros',
      amount: 0,
      budget: 100,
      color: Color(0xFFAAAAAA),
      percentage: 0.0),
];

final List<Transaction> sampleTransactions = [
  Transaction(
      title: 'Venta de productos',
      subtitle: 'Salario 15 mar',
      amount: 3500,
      isIncome: true,
      icon: Icons.trending_up),
  Transaction(
      title: 'Supermercado',
      subtitle: 'Alimentación 14 mar',
      amount: 165,
      isIncome: false,
      icon: Icons.shopping_cart_outlined),
  Transaction(
      title: 'Netflix',
      subtitle: 'Entretenimiento 13 mar',
      amount: 15,
      isIncome: false,
      icon: Icons.tv_outlined),
  Transaction(
      title: 'Gym',
      subtitle: 'Salud 12 mar',
      amount: 80,
      isIncome: false,
      icon: Icons.fitness_center),
  Transaction(
      title: 'Freelance',
      subtitle: 'Ingreso 10 mar',
      amount: 66500,
      isIncome: true,
      icon: Icons.computer_outlined),
];

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showDialog = false;
  late List<Transaction> _transactions;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _transactions = List.from(sampleTransactions);
  }

  void _deleteTransaction(int index) {
    setState(() => _transactions.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(
                onNewTransaction: () => setState(() => _showDialog = true),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _TransactionsCard(
                        transactions: _transactions,
                        onDelete: _deleteTransaction,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showDialog)
            _NewTransactionDialog(
              onClose: () => setState(() => _showDialog = false),
              onAdd: (tx) => setState(() {
                _transactions.insert(0, tx);
                _showDialog = false;
              }),
            ),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onNewTransaction;
  const _TopBar({required this.onNewTransaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text("Dashboard"),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ── Transactions ──────────────────────────────────────────────────────────────

class _TransactionsCard extends StatelessWidget {
  final List<Transaction> transactions;
  final void Function(int index) onDelete;

  const _TransactionsCard({
    required this.transactions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: transactions
          .asMap()
          .entries
          .map((e) => ListTile(
                title: Text(e.value.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onDelete(e.key),
                ),
              ))
          .toList(),
    );
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _NewTransactionDialog extends StatelessWidget {
  final VoidCallback onClose;
  final void Function(Transaction) onAdd;

  const _NewTransactionDialog({
    required this.onClose,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          onAdd(Transaction(
            title: "Nueva",
            subtitle: "Demo",
            amount: 100,
            isIncome: true,
            icon: Icons.add,
          ));
        },
        child: const Text("Agregar"),
      ),
    );
  }
}
