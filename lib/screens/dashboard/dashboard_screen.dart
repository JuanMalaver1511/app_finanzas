import 'package:flutter/material.dart';
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
      color: const Color(0xFF4A9B8E),
      percentage: 0.65),
  Category(
      name: 'Alimentación',
      amount: 165,
      budget: 300,
      color: const Color(0xFF5BB85D),
      percentage: 0.12),
  Category(
      name: 'Servicios',
      amount: 95,
      budget: 200,
      color: const Color(0xFF5BA0D0),
      percentage: 0.07),
  Category(
      name: 'Transporte',
      amount: 85,
      budget: 150,
      color: const Color(0xFF3B6FBF),
      percentage: 0.06),
  Category(
      name: 'Salud',
      amount: 80,
      budget: 200,
      color: const Color(0xFF9B5BB8),
      percentage: 0.06),
  Category(
      name: 'Educación',
      amount: 50,
      budget: 100,
      color: const Color(0xFFD4A017),
      percentage: 0.04),
  Category(
      name: 'Entretenimiento',
      amount: 15,
      budget: 100,
      color: const Color(0xFFE05C5C),
      percentage: 0.01),
  Category(
      name: 'Ropa',
      amount: 0,
      budget: 100,
      color: const Color(0xFFB85B8A),
      percentage: 0.0),
  Category(
      name: 'Otros',
      amount: 0,
      budget: 100,
      color: const Color(0xFFAAAAAA),
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
                  onNewTransaction: () => setState(() => _showDialog = true)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary Cards ──
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Balance total',
                              amount: 'COP 60,000.00',
                              amountColor: Colors.black87,
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: const Color(0xFF4A9B8E),
                              iconBg: const Color(0xFFE8F5F3),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Ingresos',
                              amount: 'COP 70,000.00',
                              amountColor: const Color(0xFF2E7D32),
                              icon: Icons.trending_up,
                              iconColor: const Color(0xFF2E7D32),
                              iconBg: const Color(0xFFE8F5E9),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Gastos',
                              amount: 'COP 20,000.00',
                              amountColor: const Color(0xFFD32F2F),
                              icon: Icons.trending_down,
                              iconColor: const Color(0xFFD32F2F),
                              iconBg: const Color(0xFFFFEBEE),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Charts Row ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _DonutChartCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _BudgetBarsCard()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Transactions ──
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

          // ── Modal Overlay ──
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Finanzas',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onNewTransaction,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva transacción'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black45),
            onPressed: () {},
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(amount,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: amountColor)),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Donut Chart Card ──────────────────────────────────────────────────────────

class _DonutChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visible = categories.where((c) => c.percentage > 0).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gastos por categoría',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(painter: _DonutPainter(categories)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: visible
                      .map((cat) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.5),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: cat.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(cat.name,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black87)),
                                ),
                                Text(
                                    '${(cat.percentage * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Text('USD ${cat.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Category> data;
  _DonutPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 28.0;
    double startAngle = -math.pi / 2;

    for (final cat in data.where((c) => c.percentage > 0)) {
      final sweepAngle = cat.percentage * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.04,
        false,
        Paint()
          ..color = cat.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

// ── Budget Bars Card ──────────────────────────────────────────────────────────

class _BudgetBarsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gastos por categoría',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 20),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: cat.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(cat.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text(
                          'USD ${cat.amount.toStringAsFixed(2)} / USD ${cat.budget.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black38),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: cat.budget > 0
                            ? (cat.amount / cat.budget).clamp(0.0, 1.0)
                            : 0,
                        backgroundColor: const Color(0xFFEEEEEE),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Transactions Card ─────────────────────────────────────────────────────────

class _TransactionsCard extends StatelessWidget {
  final List<Transaction> transactions;
  final void Function(int index) onDelete;

  const _TransactionsCard({
    required this.transactions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transacciones recientes',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No hay transacciones aún',
                    style: TextStyle(color: Colors.black38, fontSize: 14)),
              ),
            )
          else
            ...transactions.asMap().entries.map((e) => _TransactionItem(
                  transaction: e.value,
                  onDelete: () => onDelete(e.key),
                  isLast: e.key == transactions.length - 1,
                )),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  final bool isLast;

  const _TransactionItem({
    required this.transaction,
    required this.onDelete,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: transaction.isIncome
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transaction.icon,
              color: transaction.isIncome
                  ? const Color(0xFF2E7D32)
                  : Colors.black54,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(transaction.subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black38)),
              ],
            ),
          ),
          Text(
            '${transaction.isIncome ? '+' : '-'} COP ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: transaction.isIncome
                  ? const Color(0xFF2E7D32)
                  : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline,
                color: Colors.black26, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── New Transaction Dialog ────────────────────────────────────────────────────

class _NewTransactionDialog extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(Transaction) onAdd;

  const _NewTransactionDialog({required this.onClose, required this.onAdd});

  @override
  State<_NewTransactionDialog> createState() => _NewTransactionDialogState();
}

class _NewTransactionDialogState extends State<_NewTransactionDialog> {
  bool _isIncome = false;
  String _selectedCategory = 'Alimentación';
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;

    widget.onAdd(Transaction(
      title: title,
      subtitle: _isIncome ? 'Ingreso' : _selectedCategory,
      amount: amount,
      isIncome: _isIncome,
      icon: _isIncome ? Icons.trending_up : Icons.receipt_outlined,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black38,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 460,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15), blurRadius: 30)
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nueva transacción',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87)),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Type toggle
                  Row(
                    children: [
                      Expanded(
                          child: _TypeButton(
                        label: 'Gasto',
                        selected: !_isIncome,
                        color: const Color(0xFFD32F2F),
                        onTap: () => setState(() => _isIncome = false),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _TypeButton(
                        label: 'Ingreso',
                        selected: _isIncome,
                        color: const Color(0xFF2E7D32),
                        onTap: () => setState(() => _isIncome = true),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _InputField(
                    label: 'Descripción',
                    controller: _titleController,
                    hint: 'Ej: Supermercado',
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  _InputField(
                    label: 'Monto',
                    controller: _amountController,
                    hint: '0.00',
                    isNumber: true,
                  ),
                  const SizedBox(height: 12),

                  // Category (only for expenses)
                  if (!_isIncome) ...[
                    const Text('Categoría',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(
                              value: c.name, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A623),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Agregar transacción',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : const Color(0xFFF5F5F5),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? color : Colors.black45,
              )),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isNumber;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFF5A623), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
