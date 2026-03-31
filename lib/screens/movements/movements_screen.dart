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
const kGreenBtn = Color(0xFF27AE60);
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
        vsync: this, duration: const Duration(milliseconds: 400));
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
      _fadeCtrl
        ..reset()
        ..forward();
    });
  }

  Future<void> _loadCategories() async {
    final snap =
        await FirebaseFirestore.instance.collection('categories').get();

    setState(() {
      _categories = snap.docs.map((d) => d.data()).toList();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: kBg,

        // 🔥 BOTÓN + AGREGADO (AQUÍ ESTÁ LA CLAVE)
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(
            bottom:1, 
            right: 1,
          ),
          child: FloatingActionButton(
            onPressed: _openAddTransaction,
            backgroundColor: kAmber,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final isTablet =
                    constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
                final isDesktop = constraints.maxWidth >= 1024;

                double maxWidth;
                if (isMobile) {
                  maxWidth = constraints.maxWidth;
                } else if (isTablet) {
                  maxWidth = 900;
                } else {
                  maxWidth = 1200;
                }

                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: isDesktop
                        ? _buildDesktopLayout(maxWidth)
                        : _buildMobileLayout(isMobile),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Layout móvil/tablet — igual que antes
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
                      _buildSummaryCards(income, expense, isMobile),
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

  // Layout desktop — dos columnas, sin scroll outer
  Widget _buildDesktopLayout(double maxWidth) {
    return Column(
      children: [
        // ── AppBar fijo ──
        _buildDesktopHeader(),
        // ── Contenido en dos columnas ──
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

              return Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Columna izquierda (resumen + gráfica) ──
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildMonthSelector(),
                            const SizedBox(height: 16),
                            _buildSummaryCards(income, expense, false),
                            const SizedBox(height: 20),
                            _buildChartSection(),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // ── Columna derecha (filtros + lista) ──
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
                                      list, snap.connectionState),
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
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 12),
      child: Row(
        children: [
          // Flecha atrás con más espacio y separación clara
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kDark.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: kDark, size: 18),
            ),
          ),
          const SizedBox(width: 16), // 👈 espacio entre flecha y barra amarilla
          Container(
            width: 7,
            height: 22,
            decoration: BoxDecoration(
              color: kAmber,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Mis Movimientos',
            style: TextStyle(
              color: kDark,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────
  Widget _buildAppBar(bool isMobile) {
    return SliverAppBar(
      backgroundColor: kBg,
      elevation: 0,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/');
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kDark.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kDark, size: 16),
          ),
        ),
      ),
      title: Row(children: [
        Container(
          width: 7,
          height: 22,
          decoration: BoxDecoration(
            color: kAmber,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Mis Movimientos',
          style: TextStyle(
            color: kDark,
            fontWeight: FontWeight.w800,
            fontSize: 21,
            letterSpacing: -0.5,
          ),
        ),
      ]),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  // ─── SELECTOR DE MES ──────────────────────────────────────────────────────
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
                offset: const Offset(0, 4))
          ]),
      child: Row(children: [
        _navBtn(Icons.chevron_left_rounded, () => _changeMonth(-1)),
        Expanded(
            child: GestureDetector(
          onTap: _pickMonth,
          child: Column(children: [
            Text(_monthName(_selectedMonth.month),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kDark,
                    letterSpacing: -0.3)),
            Text('${_selectedMonth.year}',
                style: const TextStyle(fontSize: 12, color: kGrey)),
          ]),
        )),
        _navBtn(Icons.chevron_right_rounded,
            canGoNext ? () => _changeMonth(1) : null),
      ]),
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
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon,
            color: onTap == null ? kGrey.withOpacity(0.4) : kDark, size: 22),
      ),
    );
  }

  // ─── SUMMARY CARDS ────────────────────────────────────────────────────────
  Widget _buildSummaryCards(double income, double expense, bool isMobile) {
    final balance = income - expense;
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: kDark.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Balance del mes',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: kAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kAmber.withOpacity(0.3))),
              child: Text(
                  '${_monthShort(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: const TextStyle(
                      color: kAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
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
                  letterSpacing: -1,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: (balance >= 0 ? const Color(0xFF56E39F) : kRed)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (balance >= 0 ? const Color(0xFF56E39F) : kRed)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  balance >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: balance >= 0 ? const Color(0xFF56E39F) : kRed,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  balance >= 0 ? 'Balance positivo' : 'Balance negativo',
                  style: TextStyle(
                    color: balance >= 0 ? const Color(0xFF56E39F) : kRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _miniCard('Ingresos', income, kGreen, Icons.south_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _miniCard('Gastos', expense, kRed, Icons.north_rounded)),
      ]),
    ]);
  }

  Widget _miniCard(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: kGrey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(_formatCOP(value),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.3)),
          ],
        )),
      ]),
    );
  }

  // ─── GRÁFICA ──────────────────────────────────────────────────────────────
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
                offset: const Offset(0, 4))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Últimos 6 meses',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kDark,
                  letterSpacing: -0.3)),
          Row(children: [
            _legend(kGreen, 'Ingresos'),
            const SizedBox(width: 12),
            _legend(kRed, 'Gastos'),
          ]),
        ]),
        const SizedBox(height: 20),
        StreamBuilder<List<_MonthlyData>>(
          stream: _chartStream,
          builder: (_, snap) {
            if (!snap.hasData) {
              return const SizedBox(
                  height: 140,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: kAmber, strokeWidth: 2)));
            }
            return SizedBox(height: 160, child: _BarChart(data: snap.data!));
          },
        ),
      ]),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: kGrey)),
      ]);

  // ─── FILTRO CATEGORÍA ─────────────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return Row(
      children: [
        // BOTÓN TODOS
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedCategory == null ? kAmber : kCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Todos",
              style: TextStyle(
                color: _selectedCategory == null ? kDark : kGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // BOTÓN CATEGORÍAS
        GestureDetector(
          onTap: () {
            _showCategoryModal();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(20),
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
    );
  }

  void _showCategoryModal() {
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
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Nueva categoría"),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCategoryDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Nueva categoría"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Ej: 🍔 Comida",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();

                if (text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('categories')
                      .add({
                    'name': text,
                    'type': 'expense',
                  });

                  await _loadCategories();
                }

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // ─── LISTA TRANSACCIONES ─────────────────────────────────────────────────
  Widget _buildTransactionList(
      List<AppTransaction> all, ConnectionState state) {
    final list = _selectedCategory == null
        ? all
        : all.where((t) => t.category == _selectedCategory).toList();

    if (state == ConnectionState.waiting && all.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: kAmber, strokeWidth: 2)));
    }

    if (list.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: kAmberLight, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.receipt_long_outlined,
                  color: kAmber, size: 30)),
          const SizedBox(height: 16),
          const Text('Sin transacciones',
              style: TextStyle(
                  color: kDark, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('No hay registros para este período',
              style: TextStyle(color: kGrey, fontSize: 13)),
        ]),
      ));
    }

    // Agrupar por fecha
    final grouped = <String, List<AppTransaction>>{};
    for (final t in list) {
      grouped.putIfAbsent(_dateLabel(t.date), () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries
          .map((e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(e.key,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kGrey,
                              letterSpacing: 0.5))),
                  Container(
                    decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: kDark.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ]),
                    child: Column(
                      children: e.value.asMap().entries.map((entry) {
                        final isLast = entry.key == e.value.length - 1;
                        return Column(children: [
                          _transactionTile(entry.value),
                          if (!isLast)
                            Divider(height: 1, indent: 70, color: kBg),
                        ]);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ))
          .toList(),
    );
  }

  Widget _transactionTile(AppTransaction t) {
    final color = t.isIncome ? kGreen : kRed;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetail(t),
        onLongPress: () => _confirmDelete(t),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  t.emoji.isNotEmpty ? t.emoji : '💰',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kDark,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: kBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(t.category,
                        style: const TextStyle(
                            fontSize: 11,
                            color: kGrey,
                            fontWeight: FontWeight.w500))),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${t.isIncome ? '+' : '-'} ${_formatCOP(t.amount)}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.3)),
              const SizedBox(height: 2),
              Text(_timeStr(t.date),
                  style: const TextStyle(fontSize: 11, color: kGrey)),
            ]),
          ]),
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
        title: const Text('Eliminar transacción',
            style: TextStyle(fontWeight: FontWeight.w700, color: kDark)),
        content: Text('¿Eliminar "${t.title}"?',
            style: const TextStyle(color: kGrey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: kGrey))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) await _col.doc(t.id).delete();
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
                  primary: kAmber, onPrimary: kDark, onSurface: kDark)),
          child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _selectedCategory = null;
      });
    }
  }

  void _openAddTransaction() {
    showDialog(
      context: context,
      builder: (_) => AddTransactionDialog(
        onAdd: (tx) async {
          await _col.add(tx.toMap());
        },
      ),
    );
  }

  // ─── UTILS ────────────────────────────────────────────────────────────────
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
    if (d.day == now.day && d.month == now.month && d.year == now.year)
      return 'HOY';
    return '${d.day} de ${_monthName(d.month)}';
  }

  String _timeStr(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'trabajo':
        return Icons.work_outline_rounded;
      case 'ingreso':
        return Icons.savings_outlined;
      case 'entretenimiento':
        return Icons.movie_filter_outlined;
      case 'ropa':
        return Icons.checkroom_outlined;
      case 'alimentación':
        return Icons.restaurant_outlined;
      case 'transporte':
        return Icons.directions_car_outlined;
      case 'salud':
        return Icons.favorite_border_rounded;
      case 'educación':
        return Icons.school_outlined;
      case 'hogar':
        return Icons.home_outlined;
      case 'servicios':
        return Icons.receipt_outlined;
      default:
        return Icons.attach_money_rounded;
    }
  }

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
          child: Text('Sin datos', style: TextStyle(color: kGrey)));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data
          .map((d) => Expanded(
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
                      Text(d.label,
                          style: const TextStyle(
                              fontSize: 11,
                              color: kGrey,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _AnimBar extends StatelessWidget {
  final double value, max;
  final Color color;
  const _AnimBar({required this.value, required this.max, required this.color});

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
            borderRadius: BorderRadius.circular(6)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: kBg, borderRadius: BorderRadius.circular(2))),
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
        Text(t.title,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: kDark)),
        const SizedBox(height: 6),
        Text('${t.isIncome ? '+' : '-'} COP ${t.amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 20),
        _row('Categoría', t.category),
        _row('Tipo', t.isIncome ? 'Ingreso' : 'Gasto'),
        _row(
            'Fecha',
            '${t.date.day.toString().padLeft(2, '0')}/'
                '${t.date.month.toString().padLeft(2, '0')}/'
                '${t.date.year}'),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: kGrey)),
            Text(value,
                style:
                    const TextStyle(color: kDark, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
