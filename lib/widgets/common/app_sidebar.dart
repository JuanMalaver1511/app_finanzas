import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kAmber = Color(0xFFFFBB4E);
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChange;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: const BoxDecoration(
        color: kDark,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // LOGO FIJO
            Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: kAmber,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.savings, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Kybo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // MENÚ CON SCROLL
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    _item(Icons.dashboard_outlined, "Inicio", 0),
                    _item(Icons.swap_horiz, "Mov.", 1),
                    _item(Icons.pie_chart_outline, "Pres.", 2),
                    _item(Icons.bar_chart_rounded, "Reportes", 3),
                    _item(Icons.flag_outlined, "Metas", 4),
                    _item(Icons.credit_card, "Deudas", 5),
                    _item(Icons.person_outline, "Perfil", 6),
                  ],
                ),
              ),
            ),

            // SALIR FIJO ABAJO
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (context) {
                    return Center(
                      child: Material(
                        color: Colors.transparent,
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
                              const SizedBox(height: 14),
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await FirebaseAuth.instance.signOut();
                                    },
                                    child: const Text("Cerrar sesión"),
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
              child: const Padding(
                padding: EdgeInsets.only(bottom: 14, top: 8),
                child: Column(
                  children: [
                    Icon(Icons.logout, color: Colors.white70),
                    SizedBox(height: 4),
                    Text(
                      "Salir",
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final active = index == selectedIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChange(index),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween(begin: 0, end: active ? 1 : 0),
          builder: (context, value, child) {
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        active ? Colors.white : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.15),
                              blurRadius: 12,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: active ? kDark : Colors.white70,
                    size: 20 + (value * 2),
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 9.5,
                    color: active ? Colors.white : Colors.white60,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(label),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
