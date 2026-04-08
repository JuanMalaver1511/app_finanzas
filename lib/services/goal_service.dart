import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/goal_model.dart';
import '../models/goal_contribution_model.dart';
import '../utils/goal_calculator.dart';

class GoalService {
  GoalService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _goalsRef {
    return _firestore.collection('users').doc(_uid).collection('goals');
  }

  CollectionReference<Map<String, dynamic>> contributionsRef(String goalId) {
    return _goalsRef.doc(goalId).collection('contributions');
  }

  Stream<List<GoalModel>> streamGoals() {
    return _goalsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GoalModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<GoalModel>> getGoals() async {
    final snapshot = await _goalsRef
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => GoalModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<GoalModel?> streamGoalById(String goalId) {
    return _goalsRef.doc(goalId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GoalModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<GoalModel?> getGoalById(String goalId) async {
    final doc = await _goalsRef.doc(goalId).get();

    if (!doc.exists || doc.data() == null) return null;

    return GoalModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
    required GoalSavingFrequency savingFrequency,
    String? imageUrl,
    String? motivation,
    double initialSavedAmount = 0,
  }) async {
    final now = DateTime.now();

    final calculation = GoalCalculator.calculate(
      targetAmount: targetAmount,
      savedAmount: initialSavedAmount,
      deadline: deadline,
      frequency: savingFrequency,
      now: now,
    );

    final docRef = _goalsRef.doc();

    final goal = GoalModel(
      id: docRef.id,
      userId: _uid,
      title: title.trim(),
      imageUrl: imageUrl,
      targetAmount: targetAmount,
      savedAmount: initialSavedAmount,
      deadline: deadline,
      savingFrequency: savingFrequency,
      suggestedAmount: calculation.suggestedAmountPerPeriod,
      status: calculation.status,
      motivation: motivation?.trim().isEmpty == true ? null : motivation?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(goal.toMap());

    if (initialSavedAmount > 0) {
      await contributionsRef(docRef.id).add(
        GoalContributionModel(
          id: '',
          goalId: docRef.id,
          amount: initialSavedAmount,
          note: 'Ahorro inicial',
          createdAt: now,
        ).toMap(),
      );
    }

    return docRef.id;
  }

  Future<void> updateGoal({
    required String goalId,
    String? title,
    double? targetAmount,
    DateTime? deadline,
    GoalSavingFrequency? savingFrequency,
    String? imageUrl,
    String? motivation,
  }) async {
    final currentGoal = await getGoalById(goalId);

    if (currentGoal == null) {
      throw Exception('La meta no existe.');
    }

    final updatedTitle = title?.trim() ?? currentGoal.title;
    final updatedTargetAmount = targetAmount ?? currentGoal.targetAmount;
    final updatedDeadline = deadline ?? currentGoal.deadline;
    final updatedFrequency = savingFrequency ?? currentGoal.savingFrequency;
    final updatedImageUrl = imageUrl ?? currentGoal.imageUrl;
    final updatedMotivation = motivation ?? currentGoal.motivation;

    final calculation = GoalCalculator.calculate(
      targetAmount: updatedTargetAmount,
      savedAmount: currentGoal.savedAmount,
      deadline: updatedDeadline,
      frequency: updatedFrequency,
    );

    await _goalsRef.doc(goalId).update({
      'title': updatedTitle,
      'targetAmount': updatedTargetAmount,
      'deadline': Timestamp.fromDate(updatedDeadline),
      'savingFrequency': updatedFrequency.name,
      'imageUrl': updatedImageUrl,
      'motivation': updatedMotivation,
      'suggestedAmount': calculation.suggestedAmountPerPeriod,
      'status': calculation.status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGoal(String goalId) async {
    final contributionsSnapshot = await contributionsRef(goalId).get();

    final batch = _firestore.batch();

    for (final doc in contributionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_goalsRef.doc(goalId));

    await batch.commit();
  }

  Stream<List<GoalContributionModel>> streamContributions(String goalId) {
    return contributionsRef(goalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GoalContributionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<GoalContributionModel>> getContributions(String goalId) async {
    final snapshot = await contributionsRef(goalId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => GoalContributionModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> addContribution({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    if (amount <= 0) {
      throw Exception('El aporte debe ser mayor a 0.');
    }

    final goal = await getGoalById(goalId);

    if (goal == null) {
      throw Exception('La meta no existe.');
    }

    final now = DateTime.now();
    final newSavedAmount = goal.savedAmount + amount;

    final calculation = GoalCalculator.calculate(
      targetAmount: goal.targetAmount,
      savedAmount: newSavedAmount,
      deadline: goal.deadline,
      frequency: goal.savingFrequency,
      now: now,
    );

    final batch = _firestore.batch();

    final contributionDoc = contributionsRef(goalId).doc();
    batch.set(
      contributionDoc,
      GoalContributionModel(
        id: contributionDoc.id,
        goalId: goalId,
        amount: amount,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        createdAt: now,
      ).toMap(),
    );

    batch.update(_goalsRef.doc(goalId), {
      'savedAmount': newSavedAmount,
      'suggestedAmount': calculation.suggestedAmountPerPeriod,
      'status': calculation.status.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  Future<void> recalculateGoal(String goalId) async {
    final goal = await getGoalById(goalId);

    if (goal == null) {
      throw Exception('La meta no existe.');
    }

    final calculation = GoalCalculator.calculate(
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      deadline: goal.deadline,
      frequency: goal.savingFrequency,
    );

    await _goalsRef.doc(goalId).update({
      'suggestedAmount': calculation.suggestedAmountPerPeriod,
      'status': calculation.status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}