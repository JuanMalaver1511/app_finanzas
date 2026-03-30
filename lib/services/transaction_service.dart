import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

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

  Future<void> add(AppTransaction tx) => _col.add(tx.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();
}