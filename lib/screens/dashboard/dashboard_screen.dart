import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// ─── DATA ─────────────────────────────────────────

class Transaction {
  final String title;
  final String category;
  final double amount;
  final bool isExpense;
  final IconData icon;
  final Color color;
  final String date;

  const Transaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
    required this.icon,
    required this.color,
    required this.date,
  });
}

final List<Transaction> _transactions = [
  Transaction(
    title: 'Netflix',
    category: 'Entretenimiento',
    amount: 15.99,
    isExpense: true,
    icon: Icons.play_circle_filled,
    color: Colors.red,
    date: 'Hoy',
  ),
  Transaction(
    title: 'Salario',
    category: 'Ingreso',
    amount: 3200,
    isExpense: false,
    icon: Icons.account_balance_wallet,
    color: Colors.green,
    date: 'Ayer',
  ),
];

// ─── STATE ────────────────────────────────────────

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: _index == 0
          ? _dashboard()
          : _index == 1
              ? const Center(child: Text("Estadísticas"))
              : _profile(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Inicio"),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: "Stats"),
          NavigationDestination(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  // ─── DASHBOARD ─────────────────────────

  Widget _dashboard() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),

        Text(
          "Hola 👋",
          style: TextStyle(color: Colors.grey[600]),
        ),

        Text(
          user?.email ?? "Usuario",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Balance", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              Text(
                "\$4,596.52",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "Transacciones",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ..._transactions.map((tx) => _item(tx)),
      ],
    );
  }

  Widget _item(Transaction tx) {
    return ListTile(
      leading: Icon(tx.icon, color: tx.color),
      title: Text(tx.title),
      subtitle: Text(tx.category),
      trailing: Text(
        "${tx.isExpense ? "-" : "+"}\$${tx.amount}",
        style: TextStyle(
          color: tx.isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─── PROFILE ─────────────────────────

  Widget _profile() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(user?.email ?? ""),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pop(context);
          },
          child: const Text("Cerrar sesión"),
        )
      ],
    );
  }
}