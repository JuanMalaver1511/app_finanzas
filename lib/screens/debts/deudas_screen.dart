import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── COLORES ────────────────────────────────────────────────────────────────
const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF1D7E45);
const kGreenBtn = Color(0xFF27AE60);
const kRed = Color(0xFFE74C3C);

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Debt {
  String id;
  String nombre;
  String tipo;
  double montoTotal;
  double saldoActual;
  double cuotaMensual;
  int diaPago;

  Debt({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.montoTotal,
    required this.saldoActual,
    required this.cuotaMensual,
    required this.diaPago,
  });

  factory Debt.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      nombre: d['nombre'] ?? '',
      tipo: d['tipo'] ?? '',
      montoTotal: (d['monto_total'] ?? 0).toDouble(),
      saldoActual: (d['saldo_actual'] ?? 0).toDouble(),
      cuotaMensual: (d['cuota_mensual'] ?? 0).toDouble(),
      diaPago: d['dia_pago'] ?? 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  final user = FirebaseAuth.instance.currentUser;

  CollectionReference get debtsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('debts');

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 16),
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
            'Mis Deudas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD PRINCIPAL ────────────────────────────────────────────────────────
  Widget _mainCard(List<Debt> debts) {
    double total = debts.fold(0, (sum, d) => sum + d.saldoActual);

    return Container(
      margin: const EdgeInsets.all(16),
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
          const Text("Total deuda", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            "\$${total.toStringAsFixed(0)} COP",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Prioriza deudas con mayor interés",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // ─── CARD DEUDA ───────────────────────────────────────────────────────────
  Widget _debtCard(Debt d) {
    double progress = 1 - (d.saldoActual / d.montoTotal);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.nombre,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text("Saldo: \$${d.saldoActual.toStringAsFixed(0)}",
              style: const TextStyle(color: kGrey)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cuota: \$${d.cuotaMensual.toStringAsFixed(0)}"),
              Text("Día ${d.diaPago}", style: const TextStyle(color: kGrey)),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _registrarPago(d),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreenBtn,
              ),
              child: const Text("Pagar"),
            ),
          )
        ],
      ),
    );
  }

  // ─── REGISTRAR PAGO ───────────────────────────────────────────────────────
  void _registrarPago(Debt d) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Registrar pago"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Monto"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              double pago = double.tryParse(controller.text) ?? 0;

              await debtsRef
                  .doc(d.id)
                  .update({'saldo_actual': d.saldoActual - pago});

              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  // ─── CREAR DEUDA ──────────────────────────────────────────────────────────
  void _crearDeuda() {
    final nombre = TextEditingController();
    final monto = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nueva deuda",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: nombre,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: monto,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monto"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                double m = double.tryParse(monto.text) ?? 0;

                await debtsRef.add({
                  'nombre': nombre.text,
                  'tipo': 'personal',
                  'monto_total': m,
                  'saldo_actual': m,
                  'cuota_mensual': 0,
                  'dia_pago': 1,
                });

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _crearDeuda,
        backgroundColor: kAmber,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: debtsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final debts =
                    snapshot.data!.docs.map((e) => Debt.fromDoc(e)).toList();

                return ListView(
                  children: [
                    _mainCard(debts),
                    ...debts.map((d) => _debtCard(d))
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
