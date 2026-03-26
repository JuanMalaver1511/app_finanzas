import 'package:flutter/material.dart';

enum AlertType { success, error, warning, info }

void showCustomAlert(
  BuildContext context, {
  required String message,
  AlertType type = AlertType.info,
}) {
  final overlay = Overlay.of(context);

  late OverlayEntry overlayEntry;

  Color bgColor;
  IconData icon;

  switch (type) {
    case AlertType.success:
      bgColor = Colors.green.shade100;
      icon = Icons.check_circle;
      break;
    case AlertType.error:
      bgColor = Colors.red.shade100;
      icon = Icons.error;
      break;
    case AlertType.warning:
      bgColor = Colors.orange.shade100;
      icon = Icons.warning;
      break;
    default:
      bgColor = Colors.blue.shade100;
      icon = Icons.info;
  }

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 40,
      left: MediaQuery.of(context).size.width * 0.5 - 150,
      width: 300,
      child: _AnimatedToast(
        message: message,
        color: bgColor,
        icon: icon,
        onClose: () => overlayEntry.remove(),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

/// WIDGET ANIMADO
class _AnimatedToast extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onClose;

  const _AnimatedToast({
    required this.message,
    required this.color,
    required this.icon,
    required this.onClose,
  });

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> slide;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slide,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.black87),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Icon(Icons.close, size: 18),
              )
            ],
          ),
        ),
      ),
    );
  }
}
