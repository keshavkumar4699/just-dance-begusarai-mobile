/// Just Dance — motion primitives: subtle, alive, 150–250ms.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Motion {
  static const fast = Duration(milliseconds: 150);
  static const med = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 250);
  static const curve = Curves.easeOutCubic;
}

/// Route: fade + 8dp slide-up, 220ms.
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.med,
    reverseTransitionDuration: Motion.fast,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Motion.curve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Tappable wrapper: scales to 0.97 on press, optional light haptic.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final BorderRadius? borderRadius;
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = false,
    this.borderRadius,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  double _scale = 1.0;

  void _down(TapDownDetails _) => setState(() => _scale = 0.97);
  void _up([TapUpDetails? _]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : _down,
      onTapUp: widget.onTap == null ? null : _up,
      onTapCancel: widget.onTap == null ? null : () => _up(),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _scale,
        duration: Motion.fast,
        curve: Motion.curve,
        child: Material(
          type: MaterialType.transparency,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Count-up number text (200ms), used by chips and collection totals.
class CountUpText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String Function(num)? formatter;
  const CountUpText(this.value, {super.key, this.style, this.formatter});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.med,
      curve: Motion.curve,
      builder: (_, v, __) {
        final shown = formatter != null
            ? formatter!(v)
            : v.round().toString();
        return Text(shown, style: style);
      },
    );
  }
}

/// One-shot stagger entrance for list cards: fade + 6dp slide, 50ms apart.
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerIn({super.key, required this.index, required this.child});

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Motion.med);
    Future.delayed(Duration(milliseconds: 50 * widget.index.clamp(0, 10)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Motion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
            .animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Skeleton shimmer block for first loads.
class Shimmer extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const Shimmer({super.key, this.height = 16, this.width, this.radius = 8});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1C1C20) : const Color(0xFFECE8E0);
    // Soft opacity pulse (no gradients per brand rules).
    final pulse = 0.55 + 0.45 * (0.5 - (_c.value - 0.5).abs()) * 2;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Opacity(
          opacity: pulse,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              color: base,
            ),
          ),
        );
      },
    );
  }
}
