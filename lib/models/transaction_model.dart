import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String emoji;

  AppTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.emoji,
  });

  factory AppTransaction.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // 🔒 Seguridad: evitar nulls o documentos corruptos
    if (data == null) {
      return AppTransaction(
        id: doc.id,
        title: '',
        category: 'Otros',
        amount: 0,
        isIncome: false,
        date: DateTime.now(),
        emoji: '💰',
      );
    }

    return AppTransaction(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      category: (data['category'] ?? 'Otros').toString(),
      amount: (data['amount'] is num)
          ? (data['amount'] as num).toDouble()
          : 0.0,
      isIncome: data['isIncome'] ?? false,
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      emoji: (data['emoji'] ?? '💰').toString(), 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'isIncome': isIncome,
      'date': Timestamp.fromDate(date),
      'emoji': emoji.isNotEmpty ? emoji : '💰', 
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppTransaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    bool? isIncome,
    DateTime? date,
    String? emoji,
  }) {
    return AppTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      date: date ?? this.date,
      emoji: emoji ?? this.emoji,
    );
  }
}