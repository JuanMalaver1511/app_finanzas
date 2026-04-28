import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

const kAmber = Color(0xFFFFBB4E);
const kDark = Color(0xFF1A1A2E);

class TopBar extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final Future<void> Function() onLogout;
  final bool showNewButton;

  const TopBar({
    super.key,
    required this.onNew,
    required this.onNotifications,
    required this.onProfile,
    required this.onLogout,
    this.showNewButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= 900;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final notificationService = uid == null ? null : NotificationService(uid);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isWeb)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAmber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.savings, color: Colors.white),
                ),
              if (!isWeb) const SizedBox(width: 8),
              if (!isWeb)
                const Text(
                  'Kybo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              if (isWeb && showNewButton)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ElevatedButton.icon(
                    onPressed: onNew,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Nueva transacción'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAmber,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              _NotificationBell(
                notificationService: notificationService,
                onTap: onNotifications,
              ),
              const SizedBox(width: 6),
              if (!isWeb)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (context) {
                          return Center(
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EEF5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cerrar sesión',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      '¿Estás seguro de que deseas cerrar sesión?',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kAmber,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await onLogout();
                                          },
                                          child: const Text('Cerrar sesión'),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFF0F2F5),
                        ),
                      ),
                      child: const Icon(Icons.logout, color: kDark, size: 21),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final NotificationService? notificationService;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.notificationService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notificationService == null) {
      return _BellButton(count: 0, onTap: onTap);
    }

    return StreamBuilder<int>(
      stream: notificationService!.unreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _BellButton(count: count, onTap: onTap);
      },
    );
  }
}

class _BellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _BellButton({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFF0F2F5),
                ),
              ),
              child: AnimatedScale(
                scale: count > 0 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: kDark,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
