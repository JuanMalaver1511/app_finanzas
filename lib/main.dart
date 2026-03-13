import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF37474F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

// ─── DATA MODELS ───────────────────────────────────────────────────────────────

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
    color: const Color(0xFFE50914),
    date: 'Hoy',
  ),
  Transaction(
    title: 'Salario',
    category: 'Ingreso',
    amount: 3200.00,
    isExpense: false,
    icon: Icons.account_balance_wallet,
    color: const Color(0xFF00C853),
    date: 'Ayer',
  ),
  Transaction(
    title: 'Supermercado',
    category: 'Alimentación',
    amount: 87.50,
    isExpense: true,
    icon: Icons.shopping_cart,
    color: const Color(0xFF2196F3),
    date: 'Ayer',
  ),
  Transaction(
    title: 'Spotify',
    category: 'Entretenimiento',
    amount: 9.99,
    isExpense: true,
    icon: Icons.music_note,
    color: const Color(0xFF1DB954),
    date: '12 Mar',
  ),
  Transaction(
    title: 'Gimnasio',
    category: 'Salud',
    amount: 40.00,
    isExpense: true,
    icon: Icons.fitness_center,
    color: const Color(0xFFFF6D00),
    date: '11 Mar',
  ),
  Transaction(
    title: 'Freelance',
    category: 'Ingreso',
    amount: 450.00,
    isExpense: false,
    icon: Icons.laptop_mac,
    color: const Color(0xFF9C27B0),
    date: '10 Mar',
  ),
];

// ─── HOME PAGE ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: _selectedIndex == 0
          ? const _DashboardView()
          : _selectedIndex == 1
              ? const _StatsView()
              : const _ProfileView(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ─── DASHBOARD VIEW ────────────────────────────────────────────────────────────

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildBalanceCard()),
        SliverToBoxAdapter(child: _buildQuickActions(context)),
        SliverToBoxAdapter(
            child: _buildSectionTitle('Transacciones recientes')),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _TransactionTile(tx: _transactions[index]),
            childCount: _transactions.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buen día,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const Text(
                'Alejandro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF37474F).withOpacity(0.15),
                child: const Text(
                  'AV',
                  style: TextStyle(
                    color: Color(0xFF37474F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF37474F),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF37474F).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance total',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$4,596.52',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _BalanceStat(
                label: 'Ingresos',
                amount: '\$3,650',
                icon: Icons.arrow_downward,
                color: const Color(0xFF69F0AE),
              ),
              const SizedBox(width: 32),
              _BalanceStat(
                label: 'Gastos',
                amount: '\$1,053',
                icon: Icons.arrow_upward,
                color: const Color(0xFFFF6E6E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickActionButton(
            icon: Icons.add,
            label: 'Añadir',
            color: const Color(0xFF37474F),
            onTap: () => _showAddDialog(context),
          ),
          _QuickActionButton(
            icon: Icons.send,
            label: 'Enviar',
            color: const Color(0xFF546E7A),
            onTap: () {},
          ),
          _QuickActionButton(
            icon: Icons.account_balance,
            label: 'Banco',
            color: const Color(0xFF78909C),
            onTap: () {},
          ),
          _QuickActionButton(
            icon: Icons.more_horiz,
            label: 'Más',
            color: const Color(0xFF90A4AE),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Ver todo',
              style: TextStyle(color: Color(0xFF37474F)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddTransactionSheet(),
    );
  }
}

// ─── SMALL WIDGETS ─────────────────────────────────────────────────────────────

class _BalanceStat extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text(amount,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tx.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tx.icon, color: tx.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Text(tx.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: tx.isExpense
                      ? const Color(0xFFE53935)
                      : const Color(0xFF00C853),
                ),
              ),
              const SizedBox(height: 3),
              Text(tx.date,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ADD TRANSACTION SHEET ─────────────────────────────────────────────────────

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  bool _isExpense = true;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nueva transacción',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _TypeChip(
                label: 'Gasto',
                selected: _isExpense,
                color: const Color(0xFFE53935),
                onTap: () => setState(() => _isExpense = true),
              ),
              const SizedBox(width: 12),
              _TypeChip(
                label: 'Ingreso',
                selected: !_isExpense,
                color: const Color(0xFF00C853),
                onTap: () => setState(() => _isExpense = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '\$ ',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 32),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Descripción',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37474F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── STATS VIEW ────────────────────────────────────────────────────────────────

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 56),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          _buildMonthSelector(),
          const SizedBox(height: 24),
          _buildSpendingCategories(),
          const SizedBox(height: 24),
          _buildMonthlyBars(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: months.length,
        itemBuilder: (_, i) {
          final selected = i == 2;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF37474F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF37474F).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Text(
              months[i],
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpendingCategories() {
    final cats = [
      _CatData('Alimentación', 0.35, const Color(0xFF2196F3)),
      _CatData('Entretenimiento', 0.25, const Color(0xFF9C27B0)),
      _CatData('Salud', 0.20, const Color(0xFFFF6D00)),
      _CatData('Transporte', 0.12, const Color(0xFF00BCD4)),
      _CatData('Otros', 0.08, const Color(0xFF8BC34A)),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Por categoría',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...cats.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('${(c.pct * 100).toInt()}%',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.pct,
                      backgroundColor: c.color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(c.color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBars() {
    final data = [820.0, 1100.0, 650.0, 980.0, 1053.0, 720.0];
    final labels = ['Oct', 'Nov', 'Dic', 'Ene', 'Feb', 'Mar'];
    final max = data.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gastos mensuales',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final isLast = i == 5;
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 120 * (data[i] / max),
                    decoration: BoxDecoration(
                      color: isLast
                          ? const Color(0xFF37474F)
                          : const Color(0xFF37474F).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isLast ? const Color(0xFF37474F) : Colors.grey[400],
                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CatData {
  final String name;
  final double pct;
  final Color color;
  const _CatData(this.name, this.pct, this.color);
}

// ─── PROFILE VIEW ──────────────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 56),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          _buildMenu(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF37474F).withOpacity(0.15),
              child: const Text(
                'AV',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF37474F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Alejandro Vargas',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        Text(
          'alejandro@email.com',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF37474F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Transacciones', value: '142'),
          _Divider(),
          _StatItem(label: 'Ahorros', value: '\$1.2K'),
          _Divider(),
          _StatItem(label: 'Meses activo', value: '8'),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final items = [
      _MenuItem(Icons.notifications_outlined, 'Notificaciones',
          const Color(0xFF37474F)),
      _MenuItem(Icons.security_outlined, 'Seguridad', const Color(0xFF546E7A)),
      _MenuItem(
          Icons.credit_card_outlined, 'Mis tarjetas', const Color(0xFF78909C)),
      _MenuItem(Icons.language_outlined, 'Idioma', const Color(0xFF90A4AE)),
      _MenuItem(Icons.help_outline, 'Ayuda', const Color(0xFFB0BEC5)),
      _MenuItem(Icons.logout, 'Cerrar sesión', const Color(0xFFCFD8DC)),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey[100],
          indent: 64,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            title: Text(
              item.label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: i == items.length - 1
                    ? const Color(0xFF37474F)
                    : const Color(0xFF1A1A2E),
              ),
            ),
            trailing: i < items.length - 1
                ? Icon(Icons.chevron_right, color: Colors.grey[300])
                : null,
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem(this.icon, this.label, this.color);
}
