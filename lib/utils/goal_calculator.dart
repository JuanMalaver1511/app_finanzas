import '../models/goal_model.dart';

class GoalCalculationResult {
  final double remainingAmount;
  final int daysLeft;
  final int periodsLeft;
  final double suggestedAmountPerPeriod;
  final double progress;
  final GoalStatus status;

  const GoalCalculationResult({
    required this.remainingAmount,
    required this.daysLeft,
    required this.periodsLeft,
    required this.suggestedAmountPerPeriod,
    required this.progress,
    required this.status,
  });
}

class GoalCalculator {
  static GoalCalculationResult calculate({
    required double targetAmount,
    required double savedAmount,
    required DateTime deadline,
    required GoalSavingFrequency frequency,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    final remainingAmount =
        (targetAmount - savedAmount).clamp(0, double.infinity).toDouble();

    final progress = targetAmount <= 0
        ? 0.0
        : (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();

    final daysLeft = deadline.difference(currentDate).inDays;

    if (savedAmount >= targetAmount && targetAmount > 0) {
      return GoalCalculationResult(
        remainingAmount: 0,
        daysLeft: daysLeft < 0 ? 0 : daysLeft,
        periodsLeft: 0,
        suggestedAmountPerPeriod: 0,
        progress: 1,
        status: GoalStatus.completed,
      );
    }

    final safeDaysLeft = daysLeft < 0 ? 0 : daysLeft;
    final periodsLeft = _calculatePeriodsLeft(
      daysLeft: safeDaysLeft,
      frequency: frequency,
    );

    final suggestedAmount =
        periodsLeft <= 0 ? remainingAmount : remainingAmount / periodsLeft;

    final status = _calculateStatus(
      savedAmount: savedAmount,
      targetAmount: targetAmount,
      deadline: deadline,
      frequency: frequency,
      now: currentDate,
    );

    return GoalCalculationResult(
      remainingAmount: remainingAmount,
      daysLeft: safeDaysLeft,
      periodsLeft: periodsLeft,
      suggestedAmountPerPeriod: suggestedAmount,
      progress: progress,
      status: status,
    );
  }

  static int _calculatePeriodsLeft({
    required int daysLeft,
    required GoalSavingFrequency frequency,
  }) {
    if (daysLeft <= 0) return 0;

    switch (frequency) {
      case GoalSavingFrequency.daily:
        return daysLeft;
      case GoalSavingFrequency.weekly:
        return (daysLeft / 7).ceil();
      case GoalSavingFrequency.biweekly:
        return (daysLeft / 15).ceil();
      case GoalSavingFrequency.monthly:
        return (daysLeft / 30).ceil();
    }
  }

  static GoalStatus _calculateStatus({
    required double savedAmount,
    required double targetAmount,
    required DateTime deadline,
    required GoalSavingFrequency frequency,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    if (savedAmount >= targetAmount && targetAmount > 0) {
      return GoalStatus.completed;
    }

    if (currentDate.isAfter(deadline) && savedAmount < targetAmount) {
      return GoalStatus.delayed;
    }

    final totalDurationDays = deadline.difference(currentDate).inDays;
    if (totalDurationDays <= 0) {
      return GoalStatus.atRisk;
    }

    final result = calculateExpectedProgress(
      targetAmount: targetAmount,
      savedAmount: savedAmount,
      deadline: deadline,
      frequency: frequency,
      now: currentDate,
    );

    final actualProgress = result.$1;
    final expectedProgress = result.$2;

    if (actualProgress >= expectedProgress * 0.9) {
      return GoalStatus.active;
    }

    if (actualProgress >= expectedProgress * 0.65) {
      return GoalStatus.atRisk;
    }

    return GoalStatus.delayed;
  }

  static (double, double) calculateExpectedProgress({
    required double targetAmount,
    required double savedAmount,
    required DateTime deadline,
    required GoalSavingFrequency frequency,
    DateTime? now,
  }) {
    final currentDate = now ?? DateTime.now();

    if (targetAmount <= 0) return (0, 0);

    final createdReference = currentDate;
    final totalDays = deadline.difference(createdReference).inDays;

    if (totalDays <= 0) {
      final actual = (savedAmount / targetAmount).clamp(0.0, 1.0);
      return (actual, 1.0);
    }

    final actualProgress = (savedAmount / targetAmount).clamp(0.0, 1.0);

    // Por ahora dejamos esperado en una lógica simple lineal.
    // Luego si quieres lo mejoramos con fecha de creación real.
    const expectedProgress = 0.5;

    return (actualProgress, expectedProgress);
  }

  static String frequencyLabel(GoalSavingFrequency frequency) {
    switch (frequency) {
      case GoalSavingFrequency.daily:
        return 'Diario';
      case GoalSavingFrequency.weekly:
        return 'Semanal';
      case GoalSavingFrequency.biweekly:
        return 'Quincenal';
      case GoalSavingFrequency.monthly:
        return 'Mensual';
    }
  }

  static String statusLabel(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return 'Vas bien';
      case GoalStatus.atRisk:
        return 'En riesgo';
      case GoalStatus.delayed:
        return 'Atrasada';
      case GoalStatus.completed:
        return 'Cumplida';
    }
  }
}
