/// Just Dance — slide-to-mark-present slider.
/// Thumb follows the finger; completing fires a gold flash + check tick burst,
/// then resets. A dry/failed slide just snaps back.
library;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';

class SlideToPresent extends StatefulWidget {
  final bool alreadyPresent;
  final Future<bool> Function() onComplete;

  const SlideToPresent({
    super.key,
    required this.alreadyPresent,
    required this.onComplete,
  });

  @override
  State<SlideToPresent> createState() => SlideToPresentState();
}

class SlideToPresentState extends State<SlideToPresent>
    with TickerProviderStateMixin {
  double _progress = 0; // 0..1
  bool _completing = false;
  bool _flash = false;
  late final AnimationController _snap;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(vsync: this, duration: Motion.med);
    _snapAnim = const AlwaysStoppedAnimation(0);
    _snap.addListener(() => setState(() => _progress = _snapAnim.value));
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _animateTo(double target, {VoidCallback? then}) {
    _snapAnim = Tween(begin: _progress, end: target)
        .animate(CurvedAnimation(parent: _snap, curve: Motion.curve));
    _snap
      ..reset()
      ..forward().whenComplete(() => then?.call());
  }

  Future<void> _endDrag() async {
    if (_progress >= 0.85) {
      _animateTo(1.0, then: () async {
        setState(() => _completing = true);
        final ok = await widget.onComplete();
        if (!mounted) return;
        if (ok) {
          setState(() => _flash = true);
          await Future.delayed(const Duration(milliseconds: 550));
          if (!mounted) return;
          setState(() {
            _flash = false;
            _completing = false;
            _progress = 0;
          });
        } else {
          setState(() => _completing = false);
          _animateTo(0); // failed slide snaps back
        }
      });
    } else {
      _animateTo(0); // dry slide snaps back
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (widget.alreadyPresent) {
      return Container(
        height: 42,
        decoration: BoxDecoration(
          color: c.active.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: c.active.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: c.active, size: 17),
            const SizedBox(width: 8),
            Text('Present today',
                style: TextStyle(
                    color: c.active,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, box) {
      const thumb = 38.0;
      final trackW = box.maxWidth;
      final maxSlide = trackW - thumb - 8;
      final left = 4 + _progress * maxSlide;

      return GestureDetector(
        onHorizontalDragUpdate: _completing
            ? null
            : (d) => setState(() {
                  _progress =
                      (_progress + d.delta.dx / maxSlide).clamp(0.0, 1.0);
                }),
        onHorizontalDragEnd: _completing ? null : (_) => _endDrag(),
        child: AnimatedContainer(
          duration: Motion.fast,
          height: 46,
          decoration: BoxDecoration(
            color: _flash ? c.gold : c.surface2,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
                color: _flash ? c.gold : c.gold.withValues(alpha: 0.35),
                width: 1.2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Opacity(
                  opacity: (1 - _progress * 1.6).clamp(0.0, 1.0),
                  child: Text(
                    'Slide to mark present',
                    style: TextStyle(
                        color: c.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (_flash)
                const Center(child: _TickBurst()),
              Positioned(
                left: left,
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _flash ? Colors.black : c.gold,
                  ),
                  child: Icon(
                    _completing ? Icons.check : Icons.arrow_forward_ios,
                    size: 16,
                    color: _flash ? c.gold : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Gold check burst shown on completion.
class _TickBurst extends StatefulWidget {
  const _TickBurst();

  @override
  State<_TickBurst> createState() => _TickBurstState();
}

class _TickBurstState extends State<_TickBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Motion.curve);
    return ScaleTransition(
      scale: Tween(begin: 0.6, end: 1.0).animate(curved),
      child: FadeTransition(
        opacity: curved,
        child: const Icon(Icons.check_circle, color: Colors.black, size: 26),
      ),
    );
  }
}
