import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Callback para Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Inicializar Firebase si es necesario
      // Pero en background, puede no ser posible, así que usar notificaciones locales

      final FlutterLocalNotificationsPlugin notificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const androidDetails = AndroidNotificationDetails(
        'kybo_diario',
        'Resumen diario',
        channelDescription: 'Notificación diaria con tu resumen financiero',
        importance: Importance.high,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      final titulo = inputData?['titulo'] ?? 'Resumen Diario Kybo';
      final cuerpo =
          inputData?['cuerpo'] ?? 'Revisa tu resumen financiero diario.';

      await notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titulo,
        cuerpo,
        details,
      );

      return true;
    } catch (e) {
      return false;
    }
  });
}

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Map<String, String> _buildFinanceSummaryContent({
    required double balance,
    required double ingresos,
    required double gastos,
  }) {
    final bool positivo = balance >= 0;
    final String titulo = positivo ? 'Resumen Kybo' : 'Atencion en Kybo';
    final String cuerpo = positivo
        ? 'Balance: \$${balance.toStringAsFixed(0)}. Ingresos: \$${ingresos.toStringAsFixed(0)}. Gastos: \$${gastos.toStringAsFixed(0)}.'
        : 'Balance: \$${balance.toStringAsFixed(0)}. Ingresos: \$${ingresos.toStringAsFixed(0)}. Gastos: \$${gastos.toStringAsFixed(0)}. Revisa tus gastos.';

    return {
      'titulo': titulo,
      'cuerpo': cuerpo,
    };
  }

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(settings);

    // Request permissions
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Inicializar Workmanager en móvil
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
    }
  }

  Future<void> programarNotificacionesDiarias({
    required double balance,
    required double ingresos,
    required double gastos,
  }) async {
    await notificationsPlugin.cancelAll();

    final bool positivo = balance >= 0;

    final String titulo = positivo ? 'Resumen Kybo' : 'Atención en Kybo';

    final String cuerpo = positivo
        ? 'Tu balance del mes va positivo (\$${balance.toStringAsFixed(0)}). Sigue así.'
        : 'Tu balance del mes va negativo (\$${balance.toStringAsFixed(0)}). Revisa tus gastos.';

    const androidDetails = AndroidNotificationDetails(
      'kybo_diario',
      'Resumen diario',
      channelDescription: 'Notificación diaria con tu resumen financiero',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    final now = tz.TZDateTime.now(tz.local);

    // Schedule for 8 AM
    var scheduled8AM = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
      0,
    );

    if (scheduled8AM.isBefore(now)) {
      scheduled8AM = scheduled8AM.add(const Duration(days: 1));
    }

    await notificationsPlugin.zonedSchedule(
      1,
      titulo,
      cuerpo,
      scheduled8AM,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Schedule for 9 PM
    var scheduled9PM = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
      0,
    );

    if (scheduled9PM.isBefore(now)) {
      scheduled9PM = scheduled9PM.add(const Duration(days: 1));
    }

    await notificationsPlugin.zonedSchedule(
      2,
      titulo,
      cuerpo,
      scheduled9PM,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> enviarResumenFinancieroAhora({
    required double balance,
    required double ingresos,
    required double gastos,
  }) async {
    final content = _buildFinanceSummaryContent(
      balance: balance,
      ingresos: ingresos,
      gastos: gastos,
    );

    await mostrarNotificacion(
      titulo: content['titulo']!,
      cuerpo: content['cuerpo']!,
    );
  }

  Future<void> programarNotificacionesDiariasGenericas() async {
    await notificationsPlugin.cancelAll();

    const String titulo = 'Resumen Diario Kybo';
    const String cuerpo =
        'Revisa tu resumen financiero diario para mantener tus finanzas en orden.';

    if (kIsWeb) {
      // Para web, agregar notificaciones a Firestore
      await _agregarNotificacionWeb(titulo, cuerpo, 8);
      await _agregarNotificacionWeb(titulo, cuerpo, 21);
    } else {
      // Para móvil, usar notificaciones del sistema
      await _programarNotificacionMovil(titulo, cuerpo, 8);
      await _programarNotificacionMovil(titulo, cuerpo, 21);

      // También programar con Workmanager como backup
      await _programarConWorkmanager(titulo, cuerpo, 8);
      await _programarConWorkmanager(titulo, cuerpo, 21);
    }
  }

  Future<void> _programarNotificacionMovil(
      String titulo, String cuerpo, int hora) async {
    const androidDetails = AndroidNotificationDetails(
      'kybo_diario',
      'Resumen diario',
      channelDescription: 'Notificación diaria con tu resumen financiero',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hora,
      0,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await notificationsPlugin.zonedSchedule(
      hora, // ID único por hora
      titulo,
      cuerpo,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _programarConWorkmanager(
      String titulo, String cuerpo, int hora) async {
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, hora, 0);

    Duration delay = targetTime.isAfter(now)
        ? targetTime.difference(now)
        : targetTime.add(const Duration(days: 1)).difference(now);

    await Workmanager().registerOneOffTask(
      'daily_notification_$hora',
      'show_notification',
      initialDelay: delay,
      inputData: {
        'titulo': titulo,
        'cuerpo': cuerpo,
      },
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresCharging: false,
      ),
    );
  }

  Future<void> _agregarNotificacionWeb(
      String titulo, String cuerpo, int hora) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final notificationTime = DateTime(now.year, now.month, now.day, hora, 0);

    if (notificationTime.isBefore(now)) {
      // Si ya pasó hoy, programar para mañana
      notificationTime.add(const Duration(days: 1));
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add({
      'title': titulo,
      'message': cuerpo,
      'type': 'daily_summary',
      'createdAt': FieldValue.serverTimestamp(),
      'scheduledFor': Timestamp.fromDate(notificationTime),
      'read': false,
    });
  }

  Future<void> mostrarNotificacion({
    required String titulo,
    required String cuerpo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kybo_general',
      'Notificaciones Kybo',
      channelDescription: 'Notificaciones locales de Kybo',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      cuerpo,
      details,
    );
  }
}
