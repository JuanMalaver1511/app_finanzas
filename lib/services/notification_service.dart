import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/app_notification.dart';

class NotificationService {
  final String uid;

  NotificationService(this.uid);

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications');

  /// ==============================
  /// TIEMPO DE VIDA DE NOTIFICACIONES
  /// ==============================
  Duration _durationForType(String type) {
    switch (type) {
      case 'budget_auto_created':
        return const Duration(days: 15);

      case 'budget_warning':
      case 'budget_exceeded':
      case 'budget_over_income':
      case 'month_without_budget':
        return const Duration(days: 30);

      case 'debt_overdue':
        return const Duration(days: 15);

      case 'debt_upcoming':
        return const Duration(days: 7);

      case 'goal_at_risk':
      case 'goal_delayed':
        return const Duration(days: 15);

      case 'income_expected':
      case 'income_received':
        return const Duration(days: 10);

      case 'admin_message':
      case 'system_update':
        return const Duration(days: 60);

      default:
        return const Duration(days: 30);
    }
  }

  /// ==============================
  /// STREAMS
  /// ==============================
  Stream<List<AppNotification>> stream() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<AppNotification>> streamValid() {
    final now = Timestamp.now();

    return _ref
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList();

      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  Stream<int> unreadCount() {
    final now = Timestamp.now();

    return _ref
        .where('isRead', isEqualTo: false)
        .where('expiresAt', isGreaterThan: now)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// ==============================
  /// MARCAR COMO LEÍDA (CLAVE)
  /// ==============================
  Future<void> markAsRead(String id) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('markNotificationAsRead');

      await callable.call({
        'notificationId': id,
      });
    } catch (e) {
      print("Error marcando como leída: $e");
    }
  }

  /// ==============================
  /// MARCAR TODAS COMO LEÍDAS
  /// ==============================
  Future<void> markAllAsRead() async {
    final now = Timestamp.now();

    final snap = await _ref
        .where('isRead', isEqualTo: false)
        .where('expiresAt', isGreaterThan: now)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'isRead': true,
      });
    }

    await batch.commit();
  }

  /// ==============================
  /// ELIMINAR
  /// ==============================
  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
  }

  /// ==============================
  /// CREAR NOTIFICACIÓN
  /// ==============================
  Future<void> create({
    required String title,
    required String message,
    required String type,
    String priority = 'low',
    String source = 'system',
  }) async {
    final expiresAt = DateTime.now().add(_durationForType(type));

    await _ref.add({
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'source': source,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  /// ==============================
  /// EVITAR DUPLICADOS
  /// ==============================
  Future<bool> existsByDedupeKey(String dedupeKey) async {
    final now = Timestamp.now();

    final snap = await _ref
        .where('dedupeKey', isEqualTo: dedupeKey)
        .where('expiresAt', isGreaterThan: now)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<void> createUnique({
    required String dedupeKey,
    required String title,
    required String message,
    required String type,
    String priority = 'low',
    String source = 'system',
  }) async {
    final alreadyExists = await existsByDedupeKey(dedupeKey);

    if (alreadyExists) return;

    final expiresAt = DateTime.now().add(_durationForType(type));

    await _ref.add({
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'source': source,
      'isRead': false,
      'dedupeKey': dedupeKey,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  Future<void> createFinanceAlert({
    required String dedupeKey,
    required String title,
    required String message,
    required String type,
    String priority = 'medium',
    String source = 'system',
  }) async {
    await createUnique(
      dedupeKey: dedupeKey,
      title: title,
      message: message,
      type: type,
      priority: priority,
      source: source,
    );
  }

  Future<void> syncBudgetAfterTransaction({
    required String categoryName,
    required bool isIncome,
  }) async {
    if (isIncome) return;

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);

    final categoryKey = categoryName.trim().toLowerCase();

    final budgetSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(monthKey)
        .collection('items')
        .where('categoryKey', isEqualTo: categoryKey)
        .limit(1)
        .get();

    double planned = 0;

    if (budgetSnap.docs.isNotEmpty) {
      planned =
          (budgetSnap.docs.first.data()['planned'] as num?)?.toDouble() ?? 0;
    }

    final txSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThan: Timestamp.fromDate(monthEnd))
        .get();

    double spent = 0;

    for (final doc in txSnap.docs) {
      final data = doc.data();
      final txIsIncome = data['isIncome'] == true || data['type'] == 'income';
      if (txIsIncome) continue;

      final rawCategory =
          (data['categoryName'] ?? data['category'] ?? '').toString().trim();

      if (rawCategory.toLowerCase() == categoryKey) {
        spent += (data['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    final missingKey = 'budget_missing_with_spend_${monthKey}_$categoryKey';
    final exceededKey = 'budget_exceeded_${monthKey}_$categoryKey';
    final warningKey = 'budget_warning_${monthKey}_$categoryKey';

    if (spent <= 0) return;

    if (planned <= 0) {
      await createUnique(
        dedupeKey: missingKey,
        title: 'Gastaste sin presupuesto',
        message:
            'Ya registraste gastos en $categoryName pero no tienes presupuesto definido.',
        type: 'budget_missing_with_spend',
        priority: 'medium',
        source: 'system',
      );
      return;
    }

    if (spent >= planned) {
      await createUnique(
        dedupeKey: exceededKey,
        title: 'Presupuesto excedido',
        message: 'Superaste el presupuesto en $categoryName.',
        type: 'budget_exceeded',
        priority: 'high',
        source: 'system',
      );
      return;
    }

    if (spent >= planned * 0.8) {
      await createUnique(
        dedupeKey: warningKey,
        title: 'Estás cerca del límite',
        message: 'Ya casi alcanzas el presupuesto en $categoryName.',
        type: 'budget_warning',
        priority: 'medium',
        source: 'system',
      );
    }
  }
}
