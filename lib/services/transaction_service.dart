import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../services/notification_service.dart';

class TransactionService {
  final String uid;

  TransactionService(this.uid);

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions');

  Stream<List<AppTransaction>> stream() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppTransaction.fromDoc).toList());

  Future<void> add(AppTransaction tx) async {
    await _col.add(tx.toMap());

    // 🔥 DISPARAR NOTIFICACIONES EN TIEMPO REAL
    final notificationService = NotificationService(uid);

    await notificationService.syncBudgetAfterTransaction(
      categoryName: tx.category,
      isIncome: tx.isIncome,
    );
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> update(AppTransaction tx) => _col.doc(tx.id).update(tx.toMap());

  // RESUMEN GENERAL (ROBUSTO)
  Future<Map<String, dynamic>> getResumenMensual() async {
    final snapshot = await _col.get();

    final now = DateTime.now();

    double ingresos = 0;
    double gastos = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // AMOUNT
      double amount = 0;
      final rawAmount = data['amount'];

      if (rawAmount is int) {
        amount = rawAmount.toDouble();
      } else if (rawAmount is double) {
        amount = rawAmount;
      }

      // isIncome
      final isIncome = data['isIncome'];

      // FECHA (CLAVE)
      DateTime? date;
      if (data['date'] is Timestamp) {
        date = (data['date'] as Timestamp).toDate();
      }

      if (date == null) continue;

      // FILTRO POR MES ACTUAL
      if (date.month == now.month && date.year == now.year) {
        if (isIncome == true) {
          ingresos += amount;
        } else {
          gastos += amount;
        }
      }
    }

    final balance = ingresos - gastos;

    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'balance': balance,
      'mes': now.month,
    };
  }
}
