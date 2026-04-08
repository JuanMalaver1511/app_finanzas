import 'package:cloud_firestore/cloud_firestore.dart';

class GoalContributionModel {
  final String id;
  final String goalId;
  final double amount;
  final String? note;
  final DateTime createdAt;

  const GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  GoalContributionModel copyWith({
    String? id,
    String? goalId,
    double? amount,
    String? note,
    DateTime? createdAt,
  }) {
    return GoalContributionModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goalId': goalId,
      'amount': amount,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GoalContributionModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalContributionModel(
      id: id,
      goalId: (map['goalId'] ?? '') as String,
      amount: _toDouble(map['amount']),
      note: map['note'] as String?,
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}