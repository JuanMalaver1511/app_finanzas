import 'package:flutter/material.dart';

const kAmber = Color(0xFFFFBB4E);
const kGrey = Color(0xFF8A8A9A);
const kDark = Color(0xFF1A1A2E);

class TopBar extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onProfile;
  final Future<void> Function() onLogout;

  const TopBar({
    super.key,
    required this.onNew,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= 900;

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
          // IZQUIERDA (solo móvil + tablet)
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
                  "Kybo",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),

          // DERECHA
          Row(
            children: [
              // ➕ SOLO WEB
              if (isWeb)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: onNew,
                    icon: const Icon(Icons.add),
                    label: const Text("Nueva transacción"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              // NOTIFICACIONES
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: kDark),
              ),

              // 🚪 LOGOUT SOLO EN MÓVIL/TABLET (CON MODAL)
              if (!isWeb)
                IconButton(
                  onPressed: () {
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Cerrar sesión",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "¿Estás seguro de que deseas cerrar sesión?",
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancelar"),
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
                                      child: const Text("Cerrar sesión"),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.logout, color: kDark),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
