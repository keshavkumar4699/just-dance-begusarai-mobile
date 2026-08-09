import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class BottomNavIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const BottomNavIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<BottomNavIcon> createState() => _BottomNavIconState();
}

class _BottomNavIconState extends State<BottomNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant BottomNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const activeColor = AppColors.gold;
    final inactiveColor = isDark
        ? AppColors.darkText.withOpacity(0.45)
        : AppColors.lightText.withOpacity(0.45);
    final color = widget.isActive ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scaleAnim.value,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(widget.label,
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: color,
                      letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}