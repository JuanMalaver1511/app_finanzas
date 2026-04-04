import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool isRead;
  final String source;

  final DateTime? createdAt;
  final DateTime? expiresAt; 

  final String? dedupeKey; 

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.source,
    required this.createdAt,
    required this.expiresAt,
    this.dedupeKey,
  });

  factory AppNotification.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? _parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return AppNotification(
      id: id,
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      priority: (data['priority'] ?? 'low').toString(),
      isRead: data['isRead'] == true,
      source: (data['source'] ?? 'system').toString(),
      createdAt: _parseDate(data['createdAt']),
      expiresAt: _parseDate(data['expiresAt']), 
      dedupeKey: data['dedupeKey']?.toString(),
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}