import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;

  AppTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  factory AppTransaction.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppTransaction(
      id: doc.id,
      title: d['title'] ?? '',
      category: d['category'] ?? 'Otros',
      amount: (d['amount'] as num).toDouble(),
      isIncome: d['isIncome'] ?? false,
      date: (d['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'amount': amount,
        'isIncome': isIncome,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      };
}