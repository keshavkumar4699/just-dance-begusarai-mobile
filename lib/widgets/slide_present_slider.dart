import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../theme/app_theme.dart';

/// Slide-to-mark-present control. Thumb follows the finger; on completion a
/// gold flash + check tick burst, then resets. A dry (incomplete) slide just
/// snaps back.
class SlidePresentSlider extends StatefulWidget {
  final Future<bool> Function() onComplete;
  final bool enabled;

  const SlidePresentSlider({super.key, required this.onComplete, this.enabled = true});

  @override
  State<SlidePresentSlider> createState() => _SlidePresentSliderState();
}

class _SlidePresentSliderState extends State<SlidePresentSlider>
    with SingleTickerProviderStateMixin {
  double _drag = 0; // 0..1
  bool _dragging = false;
  bool _flash = false;
  bool _busy = false;

  late final AnimationController _tickC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _tickC.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _flash = true;
      _drag = 1;
    });
    HapticFeedback.heavyImpact();
    _tickC.forward(from: 0);
    final ok = await widget.onComplete();
    if (!mounted) return;
    setState(() => _flash = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
    if (!mounted) return;
    setState(() {
      _drag = 0;
      _busy = false;
    });
    _tickC.reset();
  }

  void _onDrag(double value) {
    if (_busy) return;
    if (!_dragging) {
      setState(() => _dragging = true);
    }
    final clamped = value.clamp(0.0, 1.0);
    if (clamped >= 0.98) {
      // Threshold reached - release and complete.
      setState(() => _dragging = false);
      _complete();
      return;
    }
    if (clamped.abs() < 0.02) {
      // tiny movement = treat as dry slide, snap back
    }
    setState(() => _drag = clamped);
  }

  void _end() {
    if (_busy) return;
    if (_dragging && _drag < 0.98) {
      // Dry slide: snap back.
      setState(() {
        _dragging = false;
        _drag = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final trackColor = _flash ? AppColors.gold : (dark ? const Color(0xFF26262B) : const Color(0xFFEFEDE6));
    final trackBorder = _flash
        ? AppColors.gold
        : AppColors.greyIcon.withValues(alpha: dark ? 0.55 : 0.4);

    return LayoutBuilder(builder: (context, c) {
      final trackW = c.maxWidth;
      final thumb = 40.0;
      final travel = trackW - thumb - 4;
      return GestureDetector(
        onHorizontalDragUpdate: (d) => _onDrag(_drag + d.delta.dx / travel),
        onHorizontalDragEnd: (_) => _end(),
        onHorizontalDragCancel: _end,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: trackBorder),
          ),
          child: Stack(
            children: [
              // Text hint.
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: _drag > 0.15 ? 0 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.chevron_right, size: 18, color: AppColors.greyIcon),
                    ),
                    Text(
                      'Slide to mark present',
                      style: wt(Theme.of(context).textTheme.labelMedium,
                          weight: 600, color: AppColors.greyIcon),
                    ),
                  ],
                ),
              ),
              // Gold flash overlay on completion.
              AnimatedOpacity(
                opacity: _flash ? 0.25 : 0,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
              ),
              // Thumb.
              AnimatedPositioned(
                duration: _dragging ? Duration.zero : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: 2 + _drag * travel,
                top: 2,
                bottom: 2,
                child: Container(
                  width: thumb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _flash ? AppColors.gold : scheme.onSurface,
                  ),
                  child: _flash
                      ? Center(
                          child: AnimatedBuilder(
                            animation: _tickC,
                            builder: (context, _) {
                              final t = Curves.easeOutBack.transform(_tickC.value);
                              return Transform.scale(
                                scale: 0.5 + t * 0.6,
                                child: const Icon(Icons.check, size: 20, color: AppColors.darkBg),
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.chevron_right, size: 22, color: AppColors.greyIcon),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
