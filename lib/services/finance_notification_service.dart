import 'notification_service.dart';

class FinanceNotificationService {
  final NotificationService _notificationService;

  FinanceNotificationService(this._notificationService);

  /// Recordatorio básico (usuario inactivo)
  Future<void> sendInactivityReminder() async {
    await _notificationService.create(
      title: "No pierdas el control 💸",
      message: "Hace días no registras movimientos. Vuelve y revisa tus finanzas.",
      type: "motivation",
      priority: "low",
      source: "system_auto",
    );
  }

  /// Alerta de gasto alto
  Future<void> sendHighSpendingAlert({
    required double gastos,
    required double ingresos,
  }) async {
    await _notificationService.create(
      title: "Cuidado con tus gastos ⚠️",
      message:
          "Tus gastos están cerca de tus ingresos. Revisa tu presupuesto para evitar desbalances.",
      type: "finance_alert",
      priority: "high",
      source: "system_auto",
    );
  }

  /// Balance negativo
  Future<void> sendNegativeBalanceAlert(double balance) async {
    await _notificationService.create(
      title: "Balance negativo 🚨",
      message:
          "Tu balance actual es negativo. Es importante ajustar tus gastos cuanto antes.",
      type: "finance_alert",
      priority: "high",
      source: "system_auto",
    );
  }

  /// Mensaje motivacional
  Future<void> sendMotivation() async {
    await _notificationService.create(
      title: "Vas bien 💪",
      message:
          "Cada registro te acerca más a tener el control total de tu dinero.",
      type: "motivation",
      priority: "low",
      source: "system_auto",
    );
  }
}