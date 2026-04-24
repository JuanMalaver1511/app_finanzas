import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notificationIA.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    await _localNotificationService.init();
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setAutoInitEnabled(true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundSubscription ??=
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _tokenRefreshSubscription ??=
        _messaging.onTokenRefresh.listen(_saveTokenForCurrentUser);

    _authSubscription ??= _auth.authStateChanges().listen((user) async {
      if (user == null) return;
      await _syncCurrentToken();
    });

    await _syncCurrentToken();
  }

  Future<void> _syncCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _saveTokenForCurrentUser(token);
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'notificationTokens': FieldValue.arrayUnion([token]),
      'lastNotificationTokenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final titulo =
        notification?.title ?? message.data['title'] ?? 'Kybo';
    final cuerpo =
        notification?.body ?? message.data['body'] ?? 'Tienes una notificacion nueva.';

    await _localNotificationService.mostrarNotificacion(
      titulo: titulo,
      cuerpo: cuerpo,
    );
  }
}
