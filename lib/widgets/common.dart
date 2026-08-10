import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../theme/app_theme.dart';

/// Tappable wrapper: scales to 0.97 on press + light haptic (spec motion).
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? radius;

  const ScaleTap({super.key, required this.child, this.onTap, this.onLongPress, this.radius});

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Pill chip with live count.
class CountChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const CountChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTap(
      onTap: onTap,
      radius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? color : AppColors.greyIcon.withValues(alpha: 0.55),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: wt(Theme.of(context).textTheme.labelMedium,
                  weight: 600,
                  color: selected ? Colors.white : scheme.onSurface.withValues(alpha: 0.85)),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: wt(Theme.of(context).textTheme.labelMedium,
                  weight: 800, color: selected ? Colors.white : color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny uppercase letter-spaced section label (Instagram style).
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: wt(Theme.of(context).textTheme.labelSmall,
          weight: 700, color: color ?? AppColors.greyIcon, letterSpacing: 1.6),
    );
  }
}

/// Friendly empty state.
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyState({super.key, required this.message, required this.icon, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.greyIcon.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: wt(Theme.of(context).textTheme.bodyMedium,
                  weight: 500, color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// Number that counts up over 200ms (spec: count chips, collections money).
class CountUpText extends StatefulWidget {
  final int value;
  final TextStyle? style;

  const CountUpText(this.value, {super.key, this.style});

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late double _from = 0;
  late double _to = widget.value.toDouble();

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = _to;
      _to = widget.value.toDouble();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Text('${(_from + (v * (_to - _from))).round()}', style: widget.style);
      },
    );
  }
}

/// Shimmer skeleton for first load.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({super.key, this.width = double.infinity, this.height = 14, this.radius = 8});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final base = dark ? const Color(0xFF1E1E22) : const Color(0xFFECEAE3);
        final hi = dark ? const Color(0xFF2A2A2F) : const Color(0xFFF6F4EE);
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: Color.lerp(base, hi, t),
          ),
        );
      },
    );
  }
}

/// Squircle avatar with placeholder fallback (spec: 1:1 squircle).
class Avatar extends StatelessWidget {
  final String? photoPath;
  final double size;

  const Avatar({super.key, this.photoPath, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.3);
    if (photoPath != null && photoPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(
          FileImageSafe.file(photoPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context),
        ),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        color: const Color(0xFF232328),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
      ),
      child: Icon(Icons.person_outline, size: size * 0.52, color: AppColors.gold),
    );
  }
}

/// Small wrapper so widgets stay const-safe with dart:io File.
class FileImageSafe {
  static File file(String path) => File(path);
}
