import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalSavingFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
}

enum GoalStatus {
  active,
  atRisk,
  delayed,
  completed,
}

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final String? imageUrl;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final GoalSavingFrequency savingFrequency;
  final double suggestedAmount;
  final GoalStatus status;
  final String? motivation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.imageUrl,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    required this.savingFrequency,
    required this.suggestedAmount,
    required this.status,
    this.motivation,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount {
    final remaining = targetAmount - savedAmount;
    return remaining < 0 ? 0 : remaining;
  }

  double get progress {
    if (targetAmount <= 0) return 0;
    final value = savedAmount / targetAmount;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  bool get isCompleted => status == GoalStatus.completed || savedAmount >= targetAmount;

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? imageUrl,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    GoalSavingFrequency? savingFrequency,
    double? suggestedAmount,
    GoalStatus? status,
    String? motivation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      savingFrequency: savingFrequency ?? this.savingFrequency,
      suggestedAmount: suggestedAmount ?? this.suggestedAmount,
      status: status ?? this.status,
      motivation: motivation ?? this.motivation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'imageUrl': imageUrl,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': Timestamp.fromDate(deadline),
      'savingFrequency': savingFrequency.name,
      'suggestedAmount': suggestedAmount,
      'status': status.name,
      'motivation': motivation,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GoalModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      imageUrl: map['imageUrl'] as String?,
      targetAmount: _toDouble(map['targetAmount']),
      savedAmount: _toDouble(map['savedAmount']),
      deadline: _toDateTime(map['deadline']),
      savingFrequency: _parseSavingFrequency(map['savingFrequency']),
      suggestedAmount: _toDouble(map['suggestedAmount']),
      status: _parseGoalStatus(map['status'], _toDouble(map['savedAmount']), _toDouble(map['targetAmount'])),
      motivation: map['motivation'] as String?,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
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

  static GoalSavingFrequency _parseSavingFrequency(dynamic value) {
    switch ((value ?? '').toString()) {
      case 'daily':
        return GoalSavingFrequency.daily;
      case 'weekly':
        return GoalSavingFrequency.weekly;
      case 'biweekly':
        return GoalSavingFrequency.biweekly;
      case 'monthly':
        return GoalSavingFrequency.monthly;
      default:
        return GoalSavingFrequency.monthly;
    }
  }

  static GoalStatus _parseGoalStatus(dynamic value, double savedAmount, double targetAmount) {
    if (savedAmount >= targetAmount && targetAmount > 0) {
      return GoalStatus.completed;
    }

    switch ((value ?? '').toString()) {
      case 'active':
        return GoalStatus.active;
      case 'atRisk':
        return GoalStatus.atRisk;
      case 'delayed':
        return GoalStatus.delayed;
      case 'completed':
        return GoalStatus.completed;
      default:
        return GoalStatus.active;
    }
  }
}