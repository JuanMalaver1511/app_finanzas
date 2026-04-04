import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationService {
  final String uid;

  NotificationService(this.uid);

  CollectionReference<Map<String, dynamic>> get _ref => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('notifications');

  Duration _durationForType(String type) {
    switch (type) {
      case 'budget_auto_created':
        return const Duration(days: 15);

      case 'budget_warning':
      case 'budget_exceeded':
      case 'budget_over_income':
      case 'month_without_budget':
        return const Duration(days: 30);

      case 'admin_message':
      case 'system_update':
        return const Duration(days: 60);

      default:
        return const Duration(days: 30);
    }
  }

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

  Future<void> markAsRead(String id) async {
    await _ref.doc(id).update({
      'isRead': true,
    });
  }

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

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
  }

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
}