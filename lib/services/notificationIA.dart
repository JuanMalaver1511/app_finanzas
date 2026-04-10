import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(settings);
  }

  Future<void> programarNotificacionDiaria({
    required double balance,
    required double ingresos,
    required double gastos,
  }) async {
    await notificationsPlugin.cancelAll();

    final bool positivo = balance >= 0;
    final String titulo = positivo ? '¡Vas bien!' : 'Atención';
    final String cuerpo = positivo
        ? 'Tu balance este mes es positivo (\$${balance.toStringAsFixed(0)}). ¡Sigue así!'
        : 'Tu balance este mes es negativo (\$${balance.toStringAsFixed(0)}). Revisa tus gastos.';

    const androidDetails = AndroidNotificationDetails(
      'kybo_diario',
      'Resumen diario',
      channelDescription: 'Notificación diaria con tu resumen financiero',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
      0,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await notificationsPlugin.zonedSchedule(
      1,
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

  Future<void> mostrarNotificacion(String titulo, String cuerpo) async {
    const androidDetails = AndroidNotificationDetails(
      'finanzas_channel',
      'Finanzas',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(0, titulo, cuerpo, details);
  }
}
