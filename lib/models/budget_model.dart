import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String category;
  final String mode; // fixed | percent
  final double? amount;
  final double? percent;
  final String period; // monthly
  final bool alert80;
  final bool alert100;
  final bool isActive;

  BudgetModel({
    required this.id,
    required this.category,
    required this.mode,
    required this.amount,
    required this.percent,
    required this.period,
    required this.alert80,
    required this.alert100,
    required this.isActive,
  });

  factory BudgetModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BudgetModel(
      id: doc.id,
      category: (data['category'] ?? '') as String,
      mode: (data['mode'] ?? 'fixed') as String,
      amount: data['amount'] != null
          ? (data['amount'] as num).toDouble()
          : null,
      percent: data['percent'] != null
          ? (data['percent'] as num).toDouble()
          : null,
      period: (data['period'] ?? 'monthly') as String,
      alert80: (data['alert80'] ?? true) as bool,
      alert100: (data['alert100'] ?? true) as bool,
      isActive: (data['isActive'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'mode': mode,
      'amount': amount,
      'percent': percent,
      'period': period,
      'alert80': alert80,
      'alert100': alert100,
      'isActive': isActive,
    };
  }
}