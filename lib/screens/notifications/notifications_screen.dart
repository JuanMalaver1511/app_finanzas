import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';

const kBg = Color(0xFFF5F6FA);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kPrimary = Color(0xFFFFBB4E);
const kPurple = Color(0xFF6366F1);
const kRed = Color(0xFFE74C3C);
const kAmber = Color(0xFFF59E0B);
const kInfo = Color(0xFF3B82F6);
const kSuccess = Color(0xFF00C897);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notificationService;
  late final String _uid;

  int _tabIndex = 0; // 0 = Todas, 1 = No leídas

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _notificationService = NotificationService(_uid);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'month_without_budget':
        return Icons.account_balance_wallet_outlined;
      case 'budget_auto_created':
        return Icons.auto_awesome_rounded;
      case 'budget_warning':
        return Icons.warning_amber_rounded;
      case 'budget_exceeded':
        return Icons.error_outline_rounded;
      case 'budget_over_income':
        return Icons.insights_outlined;
      case 'debt_overdue':
        return Icons.warning_amber_rounded;
      case 'debt_upcoming':
        return Icons.calendar_today_rounded;
      case 'goal_at_risk':
        return Icons.track_changes_rounded;
      case 'goal_delayed':
        return Icons.timelapse_rounded;
      case 'income_expected':
        return Icons.payments_outlined;
      case 'income_received':
        return Icons.check_circle_outline_rounded;
      case 'admin_message':
        return Icons.campaign_outlined;
      case 'system_update':
        return Icons.system_update_alt_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(AppNotification n) {
    switch (n.type) {
      case 'month_without_budget':
        return kPrimary;
      case 'budget_warning':
        return kAmber;
      case 'budget_exceeded':
      case 'budget_over_income':
        return kRed;
      case 'budget_auto_created':
        return kSuccess;
      case 'debt_overdue':
        return kRed;
      case 'debt_upcoming':
        return kAmber;
      case 'goal_at_risk':
        return kAmber;
      case 'goal_delayed':
        return kRed;
      case 'income_expected':
        return kInfo;
      case 'income_received':
        return kSuccess;
      case 'admin_message':
      case 'system_update':
        return kInfo;
      default:
        return _colorForPriority(n.priority);
    }
  }

  Color _colorForPriority(String priority) {
    switch (priority) {
      case 'high':
        return kRed;
      case 'medium':
        return kAmber;
      case 'low':
      default:
        return kPurple;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Ahora';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _labelForType(String type) {
    switch (type) {
      case 'month_without_budget':
        return 'Presupuesto';
      case 'budget_auto_created':
        return 'Automático';
      case 'budget_warning':
        return 'Advertencia';
      case 'budget_exceeded':
        return 'Excedido';
      case 'budget_over_income':
        return 'Riesgo';
      case 'debt_overdue':
        return 'Deuda';
      case 'debt_upcoming':
        return 'Próximo pago';
      case 'goal_at_risk':
        return 'Meta en riesgo';
      case 'goal_delayed':
        return 'Meta atrasada';
      case 'income_expected':
        return 'Ingreso';
      case 'income_received':
        return 'Confirmado';
      case 'admin_message':
        return 'Admin';
      case 'system_update':
        return 'Sistema';
      default:
        return 'Notificación';
    }
  }

  Widget _tabButton(String text, int index) {
    final selected = _tabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.16) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? kPrimary.withOpacity(0.50) : kGrey.withOpacity(0.18),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? kDark : kGrey,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 30,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _tabIndex == 0
                  ? 'No tienes notificaciones'
                  : 'No tienes notificaciones sin leer',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando ocurra algo importante en tu control financiero, aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kGrey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(AppNotification n) {
    final color = _colorForType(n);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        if (!n.isRead) {
          await _notificationService.markAsRead(n.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: n.isRead ? Colors.transparent : color.withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _iconForType(n.type),
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: const TextStyle(
                            color: kDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.message,
                    style: const TextStyle(
                      color: kGrey,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _formatDate(n.createdAt),
                          style: const TextStyle(
                            color: kGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _labelForType(n.type),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Nueva',
                            style: TextStyle(
                              color: kPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () async {
                await _notificationService.delete(n.id);
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: kGrey,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerSummary(List<AppNotification> all) {
    final unread = all.where((n) => !n.isRead).length;

    return Container(
      width: double.infinity,
      color: kCard,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unread > 0
                ? 'Tienes $unread notificación${unread > 1 ? 'es' : ''} sin leer'
                : 'Todo está al día',
            style: const TextStyle(
              color: kDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aquí verás alertas sobre presupuestos, deudas, metas e ingresos.',
            style: TextStyle(
              color: kGrey,
              fontSize: 12.8,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tabButton('Todas', 0),
              const SizedBox(width: 10),
              _tabButton('No leídas', 1),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        foregroundColor: kDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
            },
            style: TextButton.styleFrom(
              foregroundColor: kPrimary,
            ),
            child: const Text(
              'Marcar todo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.streamValid(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          final all = snapshot.data ?? [];
          final notifications =
              _tabIndex == 0 ? all : all.where((n) => !n.isRead).toList();

          return Column(
            children: [
              _headerSummary(all),
              Expanded(
                child: notifications.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return _notificationCard(n);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}