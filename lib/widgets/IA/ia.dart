import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/transaction_service.dart';
import '../../services/deepseek_IA.dart';
import '../../services/notificationIA.dart';

class IAInsightButton extends StatefulWidget {
  const IAInsightButton({super.key});

  @override
  State<IAInsightButton> createState() => _IAInsightButtonState();
}

class _IAInsightButtonState extends State<IAInsightButton> {
  final ai = DeepSeekService();
  final noti = NotificationService();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    noti.init();
  }

  // 💰 FORMATO DINERO
  String formatMoney(double value) {
    return "\$${value.toStringAsFixed(0)}";
  }

  // 📅 NOMBRE DEL MES
  String nombreMes(int mes) {
    const meses = [
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
    return meses[mes - 1];
  }

  // 📊 ESTADO FINANCIERO
  String estadoFinanciero(double balance) {
    if (balance > 0) return "Superávit 🟢";
    if (balance < 0) return "Déficit 🔴";
    return "Equilibrio 🟡";
  }

  Future<void> analizar() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final service = TransactionService(user.uid);

      final data = await service.getResumenMensual();

      final ingresos = (data['ingresos'] ?? 0).toDouble();
      final gastos = (data['gastos'] ?? 0).toDouble();
      final balance = (data['balance'] ?? 0).toDouble();
      final mes = data['mes'] ?? DateTime.now().month;

      print("📊 FIREBASE:");
      print("Ingresos: $ingresos");
      print("Gastos: $gastos");
      print("Balance: $balance");

      final respuesta = await ai.analizarFinanzas(
        ingresos: ingresos,
        gastos: gastos,
        deudas: 0,
        balance: balance,
        mes: mes,
      );

      final mensaje = """
📅 ${nombreMes(mes)}

💰 Ingresos: ${formatMoney(ingresos)}
💸 Gastos: ${formatMoney(gastos)}
📊 Balance: ${formatMoney(balance)}
📈 Estado: ${estadoFinanciero(balance)}

🤖 $respuesta
""";

      if (!mounted) return;

      // 🌐 WEB → dialog bonito
      if (kIsWeb) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("📊 Tu análisis financiero"),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              )
            ],
          ),
        );
      }
      // 📱 MOBILE → notificación
      else {
        await noti.mostrarNotificacion(
          "📊 ${nombreMes(mes)} - Estado financiero",
          mensaje,
        );
      }
    } catch (e) {
      print("🔴 ERROR IA: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al analizar datos financieros"),
          ),
        );
      }
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : analizar,
      icon: const Icon(Icons.smart_toy),
      label: Text(
        loading ? "Analizando..." : "Pregúntale a la IA",
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
