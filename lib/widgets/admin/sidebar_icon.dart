import 'package:flutter/material.dart';

class SidebarIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SidebarIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  State<SidebarIcon> createState() => _SidebarIconState();
}

class _SidebarIconState extends State<SidebarIcon> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHover
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            color: isHover ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}