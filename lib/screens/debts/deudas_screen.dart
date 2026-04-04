import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

// ─── COLORES ─────────────────────────────────────────────────────────────────
const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF27AE60);
const kRed = Color(0xFFE74C3C);
const kBlue = Color(0xFF3498DB);
const kPurple = Color(0xFF8E44AD);

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
  const DeudasScreen({
    super.key,
  });

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
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabDeudas(),
                  _buildTabAnalisis(),
                  _buildTabHistorial(),
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
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 5,
            height: 20,
            decoration: BoxDecoration(
              color: kAmber,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Mis Deudas',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddDebt(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAmber.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFFB07E1F)),
                  SizedBox(width: 4),
                  Text('Nueva',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB07E1F))),
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
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: kDark,
        unselectedLabelColor: kGrey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Deudas'),
          Tab(text: 'Análisis'),
          Tab(text: 'Historial'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1 — DEUDAS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabDeudas() {
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
            _buildResumenCards(all),
            _buildFiltros(),
            if (debts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('No hay deudas en esta categoría',
                      style: TextStyle(color: kGrey)),
                ),
              )
            else
              ...debts.asMap().entries.map((entry) {
                return _buildDebtCard(entry.value, entry.key);
              }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // ─── CARDS RESUMEN ────────────────────────────────────────────────────────
  Widget _buildResumenCards(List<Debt> debts) {
    final totalDeuda = debts.fold(0.0, (s, d) => s + d.saldoActual);
    final cuotaTotal = debts.fold(0.0, (s, d) => s + d.cuotaMensual);
    final avgInteres = debts.isEmpty
        ? 0.0
        : debts.fold(0.0, (s, d) => s + d.interes) / debts.length;
    final diasMin = debts.isEmpty ? 0 : debts.map((d) => d.diaPago).reduce(min);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          // Card principal grande
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total en deudas',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  fmt(totalDeuda),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat('Cuota mensual', fmt(cuotaTotal), Colors.white70),
                    const SizedBox(width: 24),
                    _miniStat('Próximo pago', 'Día $diasMin', Colors.white70),
                    const SizedBox(width: 24),
                    _miniStat('Deudas', '${debts.length}', Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Fila de métricas
          Row(
            children: [
              _metricCard(
                  'Interés\npromedio',
                  '${avgInteres.toStringAsFixed(1)}% EA',
                  kAmber.withOpacity(0.15),
                  kAmber),
              const SizedBox(width: 10),
              _metricCard(
                  'Deudas\nvencidas',
                  '${debts.where((d) => d.estaVencida).length}',
                  kRed.withOpacity(0.1),
                  kRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: textColor.withOpacity(0.8))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  // ─── FILTROS ──────────────────────────────────────────────────────────────
  Widget _buildFiltros() {
    final tipos = [
      ('todos', 'Todos'),
      ('personal', 'Personal'),
      ('tarjeta', 'Tarjeta'),
      ('hipoteca', 'Hipoteca'),
      ('vehiculo', 'Vehículo'),
    ];
    final ordenes = [
      ('nombre', 'A-Z'),
      ('saldo', 'Mayor saldo'),
      ('cuota', 'Mayor cuota'),
      ('interes', 'Mayor interés'),
      ('progreso', 'Más avanzada'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
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
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? kDark : kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? kDark : Colors.black12),
                  ),
                  child: Text(t.$2,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : kGrey)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
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
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? kAmber.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? kAmber.withOpacity(0.5) : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      if (sel)
                        const Icon(Icons.arrow_upward_rounded,
                            size: 11, color: Color(0xFFB07E1F)),
                      if (sel) const SizedBox(width: 3),
                      Text(o.$2,
                          style: TextStyle(
                              fontSize: 11,
                              color: sel ? const Color(0xFFB07E1F) : kGrey)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ─── CARD DE DEUDA ────────────────────────────────────────────────────────
  Widget _buildDebtCard(Debt d, int index) {
    final isExpanded = _expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: d.estaVencida
              ? kRed.withOpacity(0.4)
              : Colors.black.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Franja de vencida
          if (d.estaVencida)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 13, color: kRed),
                  const SizedBox(width: 5),
                  Text('Pago vencido · día ${d.diaPago} de este mes',
                      style: const TextStyle(fontSize: 11, color: kRed)),
                ],
              ),
            ),

          // Header de la tarjeta
          GestureDetector(
            onTap: () => setState(() {
              _expandedIndex = isExpanded ? null : index;
            }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícono de tipo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: d.tipoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(d.tipoIcono, color: d.tipoColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Nombre y meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(d.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 6),
                            _badge(
                                d.estaVencida ? 'Vencida' : 'Día ${d.diaPago}',
                                d.estaVencida ? kRed : kAmber),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_tipoLabel(d.tipo)} · ${d.mesesRestantes > 0 ? '${d.mesesRestantes} cuotas rest.' : 'Sin cuota'}',
                          style: const TextStyle(color: kGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Monto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmt(d.saldoActual),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Cuota ${fmt(d.cuotaMensual)}',
                          style: const TextStyle(color: kGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: kGrey, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Barra de progreso
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.progreso,
                    minHeight: 6,
                    backgroundColor: Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation(d.progresoColor),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pagado: ${fmt(d.montoTotal - d.saldoActual)}',
                        style: const TextStyle(fontSize: 10, color: kGrey)),
                    Text('${(d.progreso * 100).toStringAsFixed(0)}%',
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
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats en grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: [
              _statBox('Monto original', fmt(d.montoTotal)),
              _statBox('Interés anual', '${d.interes.toStringAsFixed(1)}%'),
              _statBox('Int. mensual est.', fmt(d.interesEstimadoMensual)),
              _statBox('Cuotas rest.', '${d.mesesRestantes}'),
              _statBox('Progreso', '${(d.progreso * 100).toStringAsFixed(0)}%'),
              _statBox('Día de pago', 'Día ${d.diaPago}'),
            ],
          ),
          const SizedBox(height: 14),
          // Botones de acción
          Row(
            children: [
              _actionBtn(
                label: 'Pagar',
                icon: Icons.check_circle_outline_rounded,
                color: kGreen,
                onTap: () => _showPagoModal(d),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                label: 'Editar',
                icon: Icons.edit_outlined,
                color: kBlue,
                onTap: () => _showEditarDeuda(d),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _actionBtn(
                label: 'Simular pago extra',
                icon: Icons.bolt_rounded,
                color: kAmber,
                onTap: () => _showSimulador(d),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                label: 'Eliminar',
                icon: Icons.delete_outline_rounded,
                color: kRed,
                onTap: () => _confirmDelete(d),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9, color: kGrey),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
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
  Widget _buildTabAnalisis() {
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

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            // Proyecciones
            _sectionTitle('Resumen financiero'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.07)),
              ),
              child: Column(
                children: [
                  _proyItem('Saldo total actual', fmt(totalDeuda), Colors.red),
                  _proyItem('Cuota mensual combinada', fmt(cuotaTotal),
                      Colors.orange),
                  _proyItem('Meses para saldar (máx)', '$mesesMax meses',
                      Colors.blue),
                  _proyItem('Total a pagar (estimado)', fmt(totalAPagar),
                      Colors.purple),
                  _proyItem('Deuda de mayor interés', mayorInteres.nombre,
                      Colors.red),
                  _proyItem(
                      'Más cerca de saldar', masAvanzada.nombre, Colors.green,
                      isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Distribución por tipo
            _sectionTitle('Distribución por tipo'),
            const SizedBox(height: 8),
            ..._groupByTipo(debts).entries.map((entry) {
              final pct = totalDeuda > 0 ? entry.value / totalDeuda : 0.0;
              final color =
                  debts.firstWhere((d) => d.tipo == entry.key).tipoColor;
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 8),
                              Text(_tipoLabel(entry.key),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            '${fmt(entry.value)} · ${(pct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
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

            // Ranking por interés
            _sectionTitle('Ranking por interés (prioriza estas)'),
            const SizedBox(height: 8),
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
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: rank == 1 ? kRed.withOpacity(0.1) : kBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('$rank',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: rank == 1 ? kRed : kGrey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(d.nombre,
                                  style: const TextStyle(fontSize: 13))),
                          Text(
                            '${d.interes.toStringAsFixed(1)}% EA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: rank == 1 ? kRed : kGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                })(),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kGrey)),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 12,
          color: kGrey,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3 — HISTORIAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabHistorial() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _pagosRef.orderBy('fecha', descending: true).limit(50).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final pagos =
            snap.data!.docs.map((e) => PagoHistorial.fromDoc(e)).toList();

        if (pagos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 48, color: kGrey),
                SizedBox(height: 12),
                Text('Sin pagos registrados',
                    style: TextStyle(color: kGrey, fontSize: 15)),
                SizedBox(height: 4),
                Text('Tus pagos aparecerán aquí',
                    style: TextStyle(color: kGrey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded,
                        color: kGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.deudaNombre,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}',
                          style: const TextStyle(fontSize: 11, color: kGrey),
                        ),
                      ],
                    ),
                  ),
                  Text('+${fmt(p.monto)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kGreen)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODALES / BOTTOM SHEETS
  // ─────────────────────────────────────────────────────────────────────────

  // ─── AGREGAR DEUDA ────────────────────────────────────────────────────────
  void _showAddDebt() {
    final nombre = TextEditingController();
    final monto = TextEditingController();
    final saldo = TextEditingController();
    final cuota = TextEditingController();
    final interes = TextEditingController(text: '0');
    String tipo = 'personal';
    int diaPago = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => _bottomSheet(
          title: 'Nueva deuda',
          child: Column(
            children: [
              _field('Nombre de la deuda', nombre,
                  hint: 'Ej: Tarjeta Bancolombia'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo',
                          style: TextStyle(fontSize: 12, color: kGrey)),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: tipo,
                        decoration: _inputDeco(),
                        items: const [
                          DropdownMenuItem(
                              value: 'personal', child: Text('Personal')),
                          DropdownMenuItem(
                              value: 'tarjeta', child: Text('Tarjeta')),
                          DropdownMenuItem(
                              value: 'hipoteca', child: Text('Hipoteca')),
                          DropdownMenuItem(
                              value: 'vehiculo', child: Text('Vehículo')),
                        ],
                        onChanged: (v) => setM(() => tipo = v ?? 'personal'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Día de pago',
                          style: TextStyle(fontSize: 12, color: kGrey)),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<int>(
                        value: diaPago,
                        decoration: _inputDeco(),
                        items: List.generate(
                            28,
                            (i) => DropdownMenuItem(
                                value: i + 1, child: Text('Día ${i + 1}'))),
                        onChanged: (v) => setM(() => diaPago = v ?? 1),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field('Monto total', monto,
                        hint: '0', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Saldo actual', saldo,
                        hint: '0', isNumber: true)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field('Cuota mensual', cuota,
                        hint: '0', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Interés anual %', interes,
                        hint: '0', isNumber: true)),
              ]),
              const SizedBox(height: 20),
              _submitBtn('Guardar deuda', () async {
                final n = nombre.text.trim();
                final m = double.tryParse(monto.text) ?? 0;
                final s = double.tryParse(saldo.text) ?? m;
                final c = double.tryParse(cuota.text) ?? 0;
                final i = double.tryParse(interes.text) ?? 0;
                if (n.isEmpty || m <= 0) return;
                await _debtsRef.add({
                  'nombre': n,
                  'tipo': tipo,
                  'monto_total': m,
                  'saldo_actual': s,
                  'cuota_mensual': c,
                  'dia_pago': diaPago,
                  'interes': i,
                });
                if (context.mounted) Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── EDITAR DEUDA ─────────────────────────────────────────────────────────
  void _showEditarDeuda(Debt d) {
    final nombre = TextEditingController(text: d.nombre);
    final monto = TextEditingController(text: d.montoTotal.toStringAsFixed(0));
    final saldo = TextEditingController(text: d.saldoActual.toStringAsFixed(0));
    final cuota =
        TextEditingController(text: d.cuotaMensual.toStringAsFixed(0));
    final interes = TextEditingController(text: d.interes.toStringAsFixed(1));
    String tipo = d.tipo;
    int diaPago = d.diaPago;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => _bottomSheet(
          title: 'Editar deuda',
          child: Column(
            children: [
              _field('Nombre', nombre),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo',
                          style: TextStyle(fontSize: 12, color: kGrey)),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: tipo,
                        decoration: _inputDeco(),
                        items: const [
                          DropdownMenuItem(
                              value: 'personal', child: Text('Personal')),
                          DropdownMenuItem(
                              value: 'tarjeta', child: Text('Tarjeta')),
                          DropdownMenuItem(
                              value: 'hipoteca', child: Text('Hipoteca')),
                          DropdownMenuItem(
                              value: 'vehiculo', child: Text('Vehículo')),
                        ],
                        onChanged: (v) => setM(() => tipo = v ?? d.tipo),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Día de pago',
                          style: TextStyle(fontSize: 12, color: kGrey)),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<int>(
                        value: diaPago,
                        decoration: _inputDeco(),
                        items: List.generate(
                            28,
                            (i) => DropdownMenuItem(
                                value: i + 1, child: Text('Día ${i + 1}'))),
                        onChanged: (v) => setM(() => diaPago = v ?? d.diaPago),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field('Monto original', monto, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Saldo actual', saldo, isNumber: true)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('Cuota mensual', cuota, isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field('Interés anual %', interes, isNumber: true)),
              ]),
              const SizedBox(height: 20),
              _submitBtn('Guardar cambios', () async {
                await _debtsRef.doc(d.id).update({
                  'nombre': nombre.text.trim(),
                  'tipo': tipo,
                  'monto_total': double.tryParse(monto.text) ?? d.montoTotal,
                  'saldo_actual': double.tryParse(saldo.text) ?? d.saldoActual,
                  'cuota_mensual':
                      double.tryParse(cuota.text) ?? d.cuotaMensual,
                  'dia_pago': diaPago,
                  'interes': double.tryParse(interes.text) ?? d.interes,
                });
                if (context.mounted) Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── REGISTRAR PAGO ───────────────────────────────────────────────────────
  void _showPagoModal(Debt d) {
    final montoCtrl =
        TextEditingController(text: d.cuotaMensual.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => _bottomSheet(
          title: 'Registrar pago · ${d.nombre}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info actual
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniInfo('Saldo actual', fmt(d.saldoActual)),
                    Container(width: 1, height: 30, color: Colors.black12),
                    _miniInfo('Cuota sugerida', fmt(d.cuotaMensual)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _field('Monto del pago', montoCtrl, isNumber: true),
              const SizedBox(height: 12),
              // Accesos rápidos
              Row(
                children: [
                  _quickBtn(
                      'Cuota exacta',
                      () => setM(() {
                            montoCtrl.text = d.cuotaMensual.toStringAsFixed(0);
                          })),
                  const SizedBox(width: 8),
                  _quickBtn(
                      'Pago total',
                      () => setM(() {
                            montoCtrl.text = d.saldoActual.toStringAsFixed(0);
                          })),
                  const SizedBox(width: 8),
                  _quickBtn(
                      'Doble cuota',
                      () => setM(() {
                            montoCtrl.text =
                                (d.cuotaMensual * 2).toStringAsFixed(0);
                          })),
                ],
              ),
              const SizedBox(height: 20),
              _submitBtn('Confirmar pago', () async {
                final pago = double.tryParse(montoCtrl.text) ?? 0;
                if (pago <= 0) return;
                final nuevoSaldo =
                    (d.saldoActual - pago).clamp(0, double.infinity);
                // Actualizar saldo
                await _debtsRef.doc(d.id).update({'saldo_actual': nuevoSaldo});
                // Guardar historial
                await _pagosRef.add({
                  'deuda_id': d.id,
                  'deuda_nombre': d.nombre,
                  'monto': pago,
                  'fecha': Timestamp.now(),
                });
                if (context.mounted) Navigator.pop(context);
              }, color: kGreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: kGrey)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _quickBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          child: Center(
            child:
                Text(label, style: const TextStyle(fontSize: 11, color: kDark)),
          ),
        ),
      ),
    );
  }

  // ─── SIMULADOR ────────────────────────────────────────────────────────────
  void _showSimulador(Debt d) {
    final extraCtrl = TextEditingController(text: '200000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) {
          final extra = double.tryParse(extraCtrl.text) ?? 0;
          final mesesBase = d.mesesRestantes;
          final mesesExtra = d.cuotaMensual + extra > 0
              ? (d.saldoActual / (d.cuotaMensual + extra)).ceil()
              : 0;
          final ahorroCuotas = mesesBase - mesesExtra;
          final ahorroTotal = ahorroCuotas * d.cuotaMensual;

          return _bottomSheet(
            title: 'Simulador de pago extra · ${d.nombre}',
            child: Column(
              children: [
                _field('Pago adicional mensual', extraCtrl,
                    isNumber: true, onChanged: (_) => setM(() {})),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _simStat('Sin pago extra',
                                  '$mesesBase cuotas', kGrey)),
                          Expanded(
                              child: _simStat('Con pago extra',
                                  '$mesesExtra cuotas', kGreen)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _simStat('Tiempo ahorrado',
                                  '$ahorroCuotas meses', kBlue)),
                          Expanded(
                              child: _simStat(
                                  'Dinero ahorrado', fmt(ahorroTotal), kGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Center(
                        child: Text('Cerrar',
                            style: TextStyle(fontSize: 15, color: kGrey))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _simStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: kGrey),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ─── CONFIRMAR ELIMINACIÓN ────────────────────────────────────────────────
  void _confirmDelete(Debt d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar deuda',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            '¿Estás seguro de eliminar "${d.nombre}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: kGrey, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: kGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
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
  // HELPERS DE UI
  // ─────────────────────────────────────────────────────────────────────────
  Widget _bottomSheet({required String title, required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          child,
        ],
      ),
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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
