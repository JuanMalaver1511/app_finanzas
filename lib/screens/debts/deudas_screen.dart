import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

// ─── COLORES ─────────────────────────────────────────────────────────────────
const kAmber = Color(0xFFFFBB4E);
const kAmberLight = Color(0xFFFFF3D6);
const kAmberDark = Color(0xFFE6A817);
const kBg = Color(0xFFF5F6FA);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF9098A9);
const kGreyLight = Color(0xFFEEF0F5);
const kGreen = Color(0xFF16A163);
const kGreenLight = Color(0xFFE8F8F0);
const kGreenDark = Color(0xFF0A6B40);
const kRed = Color(0xFFD63031);
const kRedLight = Color(0xFFFFF0F0);
const kRedDark = Color(0xFF8B1A1A);
const kBlue = Color(0xFF2176D9);
const kBlueLight = Color(0xFFEBF3FF);
const kBlueDark = Color(0xFF0D4E9A);
const kPurple = Color(0xFF6C3FC8);
const kPurpleLight = Color(0xFFF0EAFF);
const kPurpleDark = Color(0xFF3D1F80);

// ─────────────────────────────────────────────────────────────────────────────
// MODELO
// ─────────────────────────────────────────────────────────────────────────────
class Debt {
  String id;
  String nombre;
  String tipo;
  double montoTotal;
  double saldoActual;
  double cuotaMensual;
  int diaPago;
  double interes;

  Debt({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.montoTotal,
    required this.saldoActual,
    required this.cuotaMensual,
    required this.diaPago,
    this.interes = 0,
  });

  factory Debt.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      nombre: d['nombre'] ?? '',
      tipo: d['tipo'] ?? 'personal',
      montoTotal: (d['monto_total'] ?? 0).toDouble(),
      saldoActual: (d['saldo_actual'] ?? 0).toDouble(),
      cuotaMensual: (d['cuota_mensual'] ?? 0).toDouble(),
      diaPago: d['dia_pago'] ?? 1,
      interes: (d['interes'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'tipo': tipo,
        'monto_total': montoTotal,
        'saldo_actual': saldoActual,
        'cuota_mensual': cuotaMensual,
        'dia_pago': diaPago,
        'interes': interes,
      };

  double get progreso =>
      montoTotal > 0 ? (1 - saldoActual / montoTotal).clamp(0, 1) : 0;

  int get mesesRestantes =>
      cuotaMensual > 0 ? (saldoActual / cuotaMensual).ceil() : 0;

  double get interesEstimadoMensual => saldoActual * (interes / 100) / 12;

  bool get estaVencida => DateTime.now().day > diaPago + 3;

  Color get tipoColor {
    switch (tipo) {
      case 'tarjeta':
        return kRed;
      case 'hipoteca':
        return kPurple;
      case 'vehiculo':
        return kBlue;
      default:
        return kGreen;
    }
  }

  Color get tipoBgColor {
    switch (tipo) {
      case 'tarjeta':
        return kRedLight;
      case 'hipoteca':
        return kPurpleLight;
      case 'vehiculo':
        return kBlueLight;
      default:
        return kGreenLight;
    }
  }

  IconData get tipoIcono {
    switch (tipo) {
      case 'tarjeta':
        return Icons.credit_card_rounded;
      case 'hipoteca':
        return Icons.home_rounded;
      case 'vehiculo':
        return Icons.directions_car_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color get progresoColor {
    if (progreso > 0.7) return kGreen;
    if (progreso > 0.4) return kAmber;
    return kRed;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELO HISTORIAL
// ─────────────────────────────────────────────────────────────────────────────
class PagoHistorial {
  final String deudaNombre;
  final double monto;
  final DateTime fecha;
  final String deudaId;

  PagoHistorial({
    required this.deudaNombre,
    required this.monto,
    required this.fecha,
    required this.deudaId,
  });

  factory PagoHistorial.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PagoHistorial(
      deudaNombre: d['deuda_nombre'] ?? '',
      monto: (d['monto'] ?? 0).toDouble(),
      fecha: (d['fecha'] as Timestamp).toDate(),
      deudaId: d['deuda_id'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  String _filtroTipo = 'todos';
  String _ordenarPor = 'nombre';
  int? _expandedIndex;

  CollectionReference get _debtsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('debts');

  CollectionReference get _pagosRef => FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('pagos');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── FORMATEAR NÚMERO ─────────────────────────────────────────────────────
  String fmt(double v) {
    final abs = v.abs();
    if (abs >= 1000000) {
      return '\$${(v / 1000000).toStringAsFixed(1)}M';
    }
    return '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  // ─── DETECTAR SI ES WEB/TABLET ───────────────────────────────────────────
  bool _isWide(BuildContext context) => MediaQuery.of(context).size.width > 600;

  // ─── FILTRAR Y ORDENAR ────────────────────────────────────────────────────
  List<Debt> _filtrarOrdenar(List<Debt> all) {
    var lista = _filtroTipo == 'todos'
        ? all
        : all.where((d) => d.tipo == _filtroTipo).toList();

    switch (_ordenarPor) {
      case 'saldo':
        lista.sort((a, b) => b.saldoActual.compareTo(a.saldoActual));
        break;
      case 'cuota':
        lista.sort((a, b) => b.cuotaMensual.compareTo(a.cuotaMensual));
        break;
      case 'progreso':
        lista.sort((a, b) => b.progreso.compareTo(a.progreso));
        break;
      case 'interes':
        lista.sort((a, b) => b.interes.compareTo(a.interes));
        break;
      default:
        lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    return lista;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD PRINCIPAL
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = _isWide(context);
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: isWide
          ? null
          : GestureDetector(
              onTap: () => _showAddDebt(),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: kAmber,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kDark.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabDeudas(isWide),
                  _buildTabAnalisis(isWide),
                  _buildTabHistorial(isWide),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final isWide = _isWide(context);
    return Container(
      color: kBg,
      padding: EdgeInsets.fromLTRB(isWide ? 40 : 20, 16, isWide ? 40 : 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: kDark),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
                color: kAmber, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          const Text('Mis Deudas',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 20, color: kDark)),
          const Spacer(),
          if (isWide)
            GestureDetector(
              onTap: () => _showAddDebt(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: kAmber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Nueva deuda',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── TABBAR ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final isWide = _isWide(context);
    return Container(
      color: kBg,
      padding: EdgeInsets.fromLTRB(isWide ? 40 : 20, 0, isWide ? 40 : 20, 12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: kGreyLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          labelColor: kDark,
          unselectedLabelColor: kGrey,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'Deudas'),
            Tab(text: 'Análisis'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1 — DEUDAS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabDeudas(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream: _debtsRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!.docs.map((e) => Debt.fromDoc(e)).toList();
        final debts = _filtrarOrdenar(all);

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildResumenCards(all, isWide),
            _buildFiltros(isWide),
            if (debts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('No hay deudas en esta categoría',
                      style: TextStyle(color: kGrey)),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 0),
                child: Column(
                  children: debts
                      .asMap()
                      .entries
                      .map((e) => _buildDebtCard(e.value, e.key, isWide))
                      .toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ─── CARDS RESUMEN ────────────────────────────────────────────────────────
  Widget _buildResumenCards(List<Debt> debts, bool isWide) {
    final totalDeuda = debts.fold(0.0, (s, d) => s + d.saldoActual);
    final cuotaTotal = debts.fold(0.0, (s, d) => s + d.cuotaMensual);
    final avgInteres = debts.isEmpty
        ? 0.0
        : debts.fold(0.0, (s, d) => s + d.interes) / debts.length;
    final diasMin = debts.isEmpty ? 0 : debts.map((d) => d.diaPago).reduce(min);
    final vencidas = debts.where((d) => d.estaVencida).length;

    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 40 : 20, 0, isWide ? 40 : 20, 14),
      child: Column(
        children: [
          // Banner principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF2D2B55)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Total adeudado',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  fmt(totalDeuda),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _miniStat('Cuota mensual', fmt(cuotaTotal)),
                    _miniStat('Próximo pago', 'Día $diasMin'),
                    _miniStat('Total deudas', '${debts.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Tarjetas métricas
          Row(
            children: [
              // Interés promedio — amarillo
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: kAmberLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kAmber.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.percent_rounded,
                            size: 18, color: kAmberDark),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Interés prom.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: kAmberDark,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            '${avgInteres.toStringAsFixed(1)}% EA',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kAmberDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Deudas vencidas — rojo
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: vencidas > 0 ? kRedLight : kGreenLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (vencidas > 0 ? kRed : kGreen).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              (vencidas > 0 ? kRed : kGreen).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          vencidas > 0
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                          color: vencidas > 0 ? kRedDark : kGreenDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vencidas > 0 ? 'Vencidas' : 'Al día',
                            style: TextStyle(
                              fontSize: 11,
                              color: vencidas > 0 ? kRedDark : kGreenDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            vencidas > 0
                                ? '$vencidas deuda${vencidas > 1 ? 's' : ''}'
                                : 'Sin vencidas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: vencidas > 0 ? kRedDark : kGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── FILTROS ──────────────────────────────────────────────────────────────
  Widget _buildFiltros(bool isWide) {
    final tipos = [
      ('todos', 'Todos', Icons.apps_rounded),
      ('personal', 'Personal', Icons.person_outline_rounded),
      ('tarjeta', 'Tarjeta', Icons.credit_card_outlined),
      ('hipoteca', 'Hipoteca', Icons.home_outlined),
      ('vehiculo', 'Vehículo', Icons.directions_car_outlined),
    ];
    final ordenes = [
      ('nombre', 'A–Z'),
      ('saldo', 'Mayor saldo'),
      ('cuota', 'Mayor cuota'),
      ('interes', 'Mayor interés'),
      ('progreso', 'Más avanzada'),
    ];

    if (isWide) {
      return Padding(
        padding: EdgeInsets.fromLTRB(40, 0, 40, 14),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tipos.map((t) {
                  final sel = _filtroTipo == t.$1;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _filtroTipo = t.$1;
                      _expandedIndex = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kDark : kCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? kDark : Colors.black.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.$3,
                              size: 14, color: sel ? Colors.white : kGrey),
                          const SizedBox(width: 6),
                          Text(t.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: sel ? Colors.white : kGrey)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _ordenarPor,
                  isDense: true,
                  icon: const Icon(Icons.unfold_more_rounded,
                      size: 16, color: kGrey),
                  style: const TextStyle(
                      fontSize: 13, color: kDark, fontFamily: 'Roboto'),
                  items: ordenes
                      .map((o) => DropdownMenuItem(
                            value: o.$1,
                            child: Text(o.$2),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _ordenarPor = v ?? 'nombre';
                    _expandedIndex = null;
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ─── Versión móvil: scroll horizontal ────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: tipos.map((t) {
              final sel = _filtroTipo == t.$1;
              return GestureDetector(
                onTap: () => setState(() {
                  _filtroTipo = t.$1;
                  _expandedIndex = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? kDark : kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? kDark : Colors.black.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$3, size: 13, color: sel ? Colors.white : kGrey),
                      const SizedBox(width: 5),
                      Text(t.$2,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? Colors.white : kGrey)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: ordenes.map((o) {
              final sel = _ordenarPor == o.$1;
              return GestureDetector(
                onTap: () => setState(() {
                  _ordenarPor = o.$1;
                  _expandedIndex = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? kAmberLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: sel
                            ? kAmber.withOpacity(0.5)
                            : Colors.black.withOpacity(0.09)),
                  ),
                  child: Row(
                    children: [
                      if (sel)
                        const Icon(Icons.sort_rounded,
                            size: 12, color: kAmberDark),
                      if (sel) const SizedBox(width: 4),
                      Text(o.$2,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? kAmberDark : kGrey)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ─── CARD DE DEUDA ────────────────────────────────────────────────────────
  Widget _buildDebtCard(Debt d, int index, [bool isWide = false]) {
    final isExpanded = _expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.fromLTRB(isWide ? 0 : 20, 0, isWide ? 0 : 20, 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: d.estaVencida
              ? kRed.withOpacity(0.35)
              : Colors.black.withOpacity(0.07),
          width: d.estaVencida ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Franja vencida
          if (d.estaVencida)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: kRedLight,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 13, color: kRedDark),
                  const SizedBox(width: 6),
                  Text('Pago vencido · venció el día ${d.diaPago}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: kRedDark,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          // Header
          GestureDetector(
            onTap: () => setState(() {
              _expandedIndex = isExpanded ? null : index;
            }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: d.tipoBgColor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(d.tipoIcono, color: d.tipoColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(d.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: kDark),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 7),
                            _badge(
                              d.estaVencida ? 'Vencida' : 'Día ${d.diaPago}',
                              d.estaVencida ? kRedLight : kAmberLight,
                              d.estaVencida ? kRedDark : kAmberDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_tipoLabel(d.tipo)}${d.mesesRestantes > 0 ? '  ·  ${d.mesesRestantes} cuotas restantes' : ''}',
                          style: const TextStyle(color: kGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmt(d.saldoActual),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: kDark)),
                      const SizedBox(height: 1),
                      Text('Cuota ${fmt(d.cuotaMensual)}',
                          style: const TextStyle(color: kGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: kGrey, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Barra de progreso
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: d.progreso,
                    minHeight: 7,
                    backgroundColor: Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation(d.progresoColor),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pagado: ${fmt(d.montoTotal - d.saldoActual)}',
                        style: const TextStyle(fontSize: 10, color: kGrey)),
                    Text('${(d.progreso * 100).toStringAsFixed(0)}% completado',
                        style: TextStyle(
                            fontSize: 10,
                            color: d.progresoColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          // Sección expandida
          if (isExpanded) _buildExpandedSection(d),
        ],
      ),
    );
  }

  // ─── SECCIÓN EXPANDIDA ────────────────────────────────────────────────────
  Widget _buildExpandedSection(Debt d) {
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Stats compactos en fila
          Row(
            children: [
              _statChip(
                  Icons.attach_money_rounded, 'Original', fmt(d.montoTotal)),
              const SizedBox(width: 8),
              _statChip(Icons.trending_up_rounded, 'Interés',
                  '${d.interes.toStringAsFixed(1)}% EA'),
              const SizedBox(width: 8),
              _statChip(
                  Icons.calendar_today_rounded, 'Día pago', 'Día ${d.diaPago}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip(
                  Icons.loop_rounded, 'Cuotas rest.', '${d.mesesRestantes}'),
              const SizedBox(width: 8),
              _statChip(Icons.savings_outlined, 'Int. mensual',
                  fmt(d.interesEstimadoMensual)),
              const SizedBox(width: 8),
              _statChip(Icons.pie_chart_outline_rounded, 'Avance',
                  '${(d.progreso * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 12),
          // Botones de acción — fila de 4
          Row(
            children: [
              _actionBtn2(
                  label: 'Pagar',
                  icon: Icons.check_rounded,
                  color: kGreen,
                  bg: kGreenLight,
                  onTap: () => _showPagoModal(d)),
              const SizedBox(width: 8),
              _actionBtn2(
                  label: 'Editar',
                  icon: Icons.edit_rounded,
                  color: kBlue,
                  bg: kBlueLight,
                  onTap: () => _showEditarDeuda(d)),
              const SizedBox(width: 8),
              _actionBtn2(
                  label: 'Simular',
                  icon: Icons.bolt_rounded,
                  color: kAmberDark,
                  bg: kAmberLight,
                  onTap: () => _showSimulador(d)),
              const SizedBox(width: 8),
              _actionBtn2(
                  label: 'Eliminar',
                  icon: Icons.delete_rounded,
                  color: kRed,
                  bg: kRedLight,
                  onTap: () => _confirmDelete(d)),
            ],
          ),
        ],
      ),
    );
  }

  // stat chip compacto
  Widget _statChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: kGrey),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 9, color: kGrey)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kDark),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn2({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  String _tipoLabel(String tipo) {
    const m = {
      'personal': 'Personal',
      'tarjeta': 'Tarjeta',
      'hipoteca': 'Hipoteca',
      'vehiculo': 'Vehículo',
    };
    return m[tipo] ?? tipo;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2 — ANÁLISIS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabAnalisis(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream: _debtsRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final debts = snap.data!.docs.map((e) => Debt.fromDoc(e)).toList();
        if (debts.isEmpty) {
          return const Center(
              child: Text('Sin deudas para analizar',
                  style: TextStyle(color: kGrey)));
        }

        final totalDeuda = debts.fold(0.0, (s, d) => s + d.saldoActual);
        final cuotaTotal = debts.fold(0.0, (s, d) => s + d.cuotaMensual);
        final mesesMax = debts.map((d) => d.mesesRestantes).reduce(max);
        final totalAPagar = cuotaTotal * mesesMax;
        final mayorInteres =
            debts.reduce((a, b) => a.interes > b.interes ? a : b);
        final masAvanzada =
            debts.reduce((a, b) => a.progreso > b.progreso ? a : b);

        final content = [
          _sectionTitle('Resumen financiero'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.07)),
            ),
            child: Column(
              children: [
                _proyItem('Saldo total actual', fmt(totalDeuda), kRed),
                _proyItem('Cuota mensual combinada', fmt(cuotaTotal), kAmber),
                _proyItem('Meses para saldar (máx)', '$mesesMax meses', kBlue),
                _proyItem('Total a pagar estimado', fmt(totalAPagar), kPurple),
                _proyItem('Mayor interés', mayorInteres.nombre, kRed),
                _proyItem('Más cerca de saldar', masAvanzada.nombre, kGreen,
                    isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Distribución por tipo'),
          const SizedBox(height: 10),
          ..._groupByTipo(debts).entries.map((entry) {
            final pct = totalDeuda > 0 ? entry.value / totalDeuda : 0.0;
            final color =
                debts.firstWhere((d) => d.tipo == entry.key).tipoColor;
            final bgColor =
                debts.firstWhere((d) => d.tipo == entry.key).tipoBgColor;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(9)),
                          child: Icon(
                              debts
                                  .firstWhere((d) => d.tipo == entry.key)
                                  .tipoIcono,
                              size: 15,
                              color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_tipoLabel(entry.key),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        Text(
                          '${fmt(entry.value)}  ·  ${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: Colors.black.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          _sectionTitle('Ranking por interés (prioriza estas)'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.07)),
            ),
            child: Column(
              children: (() {
                final sorted = [...debts]
                  ..sort((a, b) => b.interes.compareTo(a.interes));
                return sorted.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final d = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: e.key < sorted.length - 1
                          ? Border(
                              bottom: BorderSide(
                                  color: Colors.black.withOpacity(0.06)))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: rank == 1 ? kRedLight : kGreyLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('$rank',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: rank == 1 ? kRedDark : kGrey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(d.nombre,
                                style: const TextStyle(
                                    fontSize: 13, color: kDark))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: rank == 1 ? kRedLight : kGreyLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${d.interes.toStringAsFixed(1)}% EA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rank == 1 ? kRedDark : kGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              })(),
            ),
          ),
        ];

        return ListView(
          padding:
              EdgeInsets.fromLTRB(isWide ? 40 : 20, 8, isWide ? 40 : 20, 20),
          children: content,
        );
      },
    );
  }

  Map<String, double> _groupByTipo(List<Debt> debts) {
    final map = <String, double>{};
    for (var d in debts) {
      map[d.tipo] = (map[d.tipo] ?? 0) + d.saldoActual;
    }
    return map;
  }

  Widget _proyItem(String label, String value, Color color,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kGrey)),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11,
          color: kGrey,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8));

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3 — HISTORIAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabHistorial(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _pagosRef.orderBy('fecha', descending: true).limit(50).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final pagos =
            snap.data!.docs.map((e) => PagoHistorial.fromDoc(e)).toList();

        if (pagos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: kGreyLight),
                SizedBox(height: 12),
                Text('Sin pagos registrados',
                    style: TextStyle(
                        color: kGrey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text('Tus pagos aparecerán aquí',
                    style: TextStyle(color: kGrey, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding:
              EdgeInsets.fromLTRB(isWide ? 40 : 20, 8, isWide ? 40 : 20, 20),
          itemCount: pagos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = pagos[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.07)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: kGreenLight,
                        borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.check_rounded,
                        color: kGreenDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.deudaNombre,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kDark)),
                        const SizedBox(height: 2),
                        Text(
                          '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}',
                          style: const TextStyle(fontSize: 11, color: kGrey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: kGreenLight,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('+${fmt(p.monto)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kGreenDark)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODALES — DIALOG CENTRADO (evita que el teclado tape el formulario)
  // ─────────────────────────────────────────────────────────────────────────

  void _showAddDebt() {
    final nombre = TextEditingController();
    final monto = TextEditingController();
    final saldo = TextEditingController();
    final cuota = TextEditingController();
    final interes = TextEditingController(text: '0');
    String tipo = 'personal';
    int diaPago = 1;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => _centeredDialog(
          title: 'Nueva deuda',
          icon: Icons.add_card_rounded,
          child: Column(
            children: [
              _field('Nombre de la deuda', nombre,
                  hint: 'Ej: Tarjeta Bancolombia'),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _dropdownField(
                        'Tipo',
                        tipo,
                        ['personal', 'tarjeta', 'hipoteca', 'vehiculo'],
                        ['Personal', 'Tarjeta', 'Hipoteca', 'Vehículo'],
                        (v) => setM(() => tipo = v ?? 'personal'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _dropdownIntField(
                        'Día de pago',
                        diaPago,
                        List.generate(28, (i) => i + 1),
                        List.generate(28, (i) => 'Día ${i + 1}'),
                        (v) => setM(() => diaPago = v ?? 1))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _field('Monto total', monto,
                        hint: '0', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Saldo actual', saldo,
                        hint: '0', isNumber: true)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _field('Cuota mensual', cuota,
                        hint: '0', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Interés anual %', interes,
                        hint: '0', isNumber: true)),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: _cancelBtn(() => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _submitBtn('Guardar deuda', () async {
                    final n = nombre.text.trim();
                    final m = double.tryParse(monto.text) ?? 0;
                    final s = double.tryParse(saldo.text) ?? m;
                    final c = double.tryParse(cuota.text) ?? 0;
                    final ii = double.tryParse(interes.text) ?? 0;
                    if (n.isEmpty || m <= 0) return;
                    await _debtsRef.add({
                      'nombre': n,
                      'tipo': tipo,
                      'monto_total': m,
                      'saldo_actual': s,
                      'cuota_mensual': c,
                      'dia_pago': diaPago,
                      'interes': ii,
                    });
                    if (context.mounted) Navigator.pop(context);
                  }),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditarDeuda(Debt d) {
    final nombre = TextEditingController(text: d.nombre);
    final monto = TextEditingController(text: d.montoTotal.toStringAsFixed(0));
    final saldo = TextEditingController(text: d.saldoActual.toStringAsFixed(0));
    final cuota =
        TextEditingController(text: d.cuotaMensual.toStringAsFixed(0));
    final interes = TextEditingController(text: d.interes.toStringAsFixed(1));
    String tipo = d.tipo;
    int diaPago = d.diaPago;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => _centeredDialog(
          title: 'Editar deuda',
          icon: Icons.edit_rounded,
          child: Column(
            children: [
              _field('Nombre', nombre),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _dropdownField(
                        'Tipo',
                        tipo,
                        ['personal', 'tarjeta', 'hipoteca', 'vehiculo'],
                        ['Personal', 'Tarjeta', 'Hipoteca', 'Vehículo'],
                        (v) => setM(() => tipo = v ?? d.tipo))),
                const SizedBox(width: 12),
                Expanded(
                    child: _dropdownIntField(
                        'Día de pago',
                        diaPago,
                        List.generate(28, (i) => i + 1),
                        List.generate(28, (i) => 'Día ${i + 1}'),
                        (v) => setM(() => diaPago = v ?? d.diaPago))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _field('Monto original', monto, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Saldo actual', saldo, isNumber: true)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _field('Cuota mensual', cuota, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Interés anual %', interes, isNumber: true)),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: _cancelBtn(() => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _submitBtn('Guardar cambios', () async {
                    await _debtsRef.doc(d.id).update({
                      'nombre': nombre.text.trim(),
                      'tipo': tipo,
                      'monto_total':
                          double.tryParse(monto.text) ?? d.montoTotal,
                      'saldo_actual':
                          double.tryParse(saldo.text) ?? d.saldoActual,
                      'cuota_mensual':
                          double.tryParse(cuota.text) ?? d.cuotaMensual,
                      'dia_pago': diaPago,
                      'interes': double.tryParse(interes.text) ?? d.interes,
                    });
                    if (context.mounted) Navigator.pop(context);
                  }),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showPagoModal(Debt d) {
    final montoCtrl =
        TextEditingController(text: d.cuotaMensual.toStringAsFixed(0));

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => _centeredDialog(
          title: 'Registrar pago',
          icon: Icons.check_circle_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: kBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(child: _miniInfo('Deuda', d.nombre)),
                    Container(width: 1, height: 34, color: Colors.black12),
                    Expanded(
                        child: _miniInfo('Saldo actual', fmt(d.saldoActual))),
                    Container(width: 1, height: 34, color: Colors.black12),
                    Expanded(child: _miniInfo('Cuota', fmt(d.cuotaMensual))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _field('Monto del pago', montoCtrl, isNumber: true),
              const SizedBox(height: 12),
              Row(children: [
                _quickBtn(
                    'Cuota exacta',
                    () => setM(() {
                          montoCtrl.text = d.cuotaMensual.toStringAsFixed(0);
                        })),
                const SizedBox(width: 8),
                _quickBtn(
                    'Doble cuota',
                    () => setM(() {
                          montoCtrl.text =
                              (d.cuotaMensual * 2).toStringAsFixed(0);
                        })),
                const SizedBox(width: 8),
                _quickBtn(
                    'Pago total',
                    () => setM(() {
                          montoCtrl.text = d.saldoActual.toStringAsFixed(0);
                        })),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: _cancelBtn(() => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _submitBtn('Confirmar pago', () async {
                    final pago = double.tryParse(montoCtrl.text) ?? 0;
                    if (pago <= 0) return;
                    final nuevoSaldo =
                        (d.saldoActual - pago).clamp(0, double.infinity);
                    await _debtsRef
                        .doc(d.id)
                        .update({'saldo_actual': nuevoSaldo});
                    await _pagosRef.add({
                      'deuda_id': d.id,
                      'deuda_nombre': d.nombre,
                      'monto': pago,
                      'fecha': Timestamp.now(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  }, color: kGreen),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: kGrey),
            textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: kDark),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _quickBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withOpacity(0.09)),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: kDark, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  void _showSimulador(Debt d) {
    final extraCtrl = TextEditingController(text: '200000');

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) {
          final extra = double.tryParse(extraCtrl.text) ?? 0;
          final mesesBase = d.mesesRestantes;
          final mesesExtra = d.cuotaMensual + extra > 0
              ? (d.saldoActual / (d.cuotaMensual + extra)).ceil()
              : 0;
          final ahorroCuotas = mesesBase - mesesExtra;
          final ahorroTotal = ahorroCuotas * d.cuotaMensual;

          return _centeredDialog(
            title: 'Simulador de pago extra',
            icon: Icons.bolt_rounded,
            child: Column(
              children: [
                _field('Pago adicional mensual', extraCtrl,
                    isNumber: true, onChanged: (_) => setM(() {})),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: kBg, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                            child: _simStat('Sin extra', '$mesesBase cuotas',
                                kGrey, kGreyLight)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _simStat('Con extra', '$mesesExtra cuotas',
                                kGreenDark, kGreenLight)),
                      ]),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _simStat('Tiempo ahorrado',
                                '$ahorroCuotas meses', kBlueDark, kBlueLight)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _simStat('Dinero ahorrado', fmt(ahorroTotal),
                                kGreenDark, kGreenLight)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _cancelBtn(() => Navigator.pop(context), label: 'Cerrar'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _simStat(String label, String value, Color textColor, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: kGrey),
              textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _confirmDelete(Debt d) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar deuda',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration:
                  BoxDecoration(color: kRedLight, shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_rounded,
                  color: kRedDark, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              '¿Eliminar "${d.nombre}"?\nEsta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kGrey, fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: kGrey, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await _debtsRef.doc(d.id).delete();
              if (context.mounted) {
                setState(() => _expandedIndex = null);
                Navigator.pop(context);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS DE UI — DIALOG CENTRADO SCROLLABLE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _centeredDialog({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: kAmberLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, size: 18, color: kAmberDark),
                    ),
                    const SizedBox(width: 12),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kDark)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: kGreyLight,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: kGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Dropdown genérico de String ─────────────────────────────────────────
  Widget _dropdownField(
    String label,
    String value,
    List<String> values,
    List<String> labels,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kGrey)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _inputDeco(),
          isExpanded: true,
          icon: const Icon(Icons.unfold_more_rounded, size: 18, color: kGrey),
          items: List.generate(
              values.length,
              (i) =>
                  DropdownMenuItem(value: values[i], child: Text(labels[i]))),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ─── Dropdown genérico de int ─────────────────────────────────────────────
  Widget _dropdownIntField(
    String label,
    int value,
    List<int> values,
    List<String> labels,
    void Function(int?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kGrey)),
        const SizedBox(height: 5),
        DropdownButtonFormField<int>(
          value: value,
          decoration: _inputDeco(),
          isExpanded: true,
          icon: const Icon(Icons.unfold_more_rounded, size: 18, color: kGrey),
          items: List.generate(
              values.length,
              (i) =>
                  DropdownMenuItem(value: values[i], child: Text(labels[i]))),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, bool isNumber = false, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kGrey)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          decoration: _inputDeco(hint: hint),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kGrey, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.09)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAmber, width: 1.5),
        ),
      );

  Widget _submitBtn(String label, VoidCallback onTap, {Color color = kDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _cancelBtn(VoidCallback onTap, {String label = 'Cancelar'}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kGreyLight,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: kGrey, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
