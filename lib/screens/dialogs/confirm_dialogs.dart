import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Scale-in 0.94->1.0 + fade 180ms dialog (spec motion).
Future<bool> showAppDialog(
  BuildContext context, {
  required Widget child,
  bool barrierDismissible = true,
}) async {
  final res = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: _ScaleIn(child: child),
    ),
  );
  return res ?? false;
}

class _ScaleIn extends StatefulWidget {
  final Widget child;
  const _ScaleIn({required this.child});

  @override
  State<_ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<_ScaleIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: t,
      child: ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(t),
        child: widget.child,
      ),
    );
  }
}

/// Generic confirm dialog.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  bool destructive = false,
}) {
  return showAppDialog(
    context,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
          const SizedBox(height: 10),
          Text(message, style: wt(Theme.of(context).textTheme.bodyMedium, weight: 400)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel',
                    style: wt(Theme.of(context).textTheme.labelLarge,
                        weight: 600, color: AppColors.greyIcon)),
              ),
              const SizedBox(width: 10),
              ScaleTap(
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: destructive ? AppColors.expired : AppColors.gold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(confirmLabel,
                      style: wt(Theme.of(context).textTheme.labelLarge,
                          weight: 700,
                          color: destructive ? Colors.white : AppColors.darkBg)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Type-the-name-to-confirm delete dialog.
Future<bool> typeNameDeleteDialog(BuildContext context, Student student) {
  final controller = TextEditingController();
  bool matches = false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: _ScaleIn(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete ${student.name}?',
                    style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
                const SizedBox(height: 10),
                Text(
                  'This deletes the member, their attendance and their full payment history. Type the name to confirm.',
                  style: wt(Theme.of(context).textTheme.bodyMedium, weight: 400),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Type full name'),
                  onChanged: (v) {
                    setState(() => matches = v.trim() == student.name.trim());
                  },
                  onSubmitted: (v) {
                    if (v.trim() == student.name.trim()) {
                      Navigator.of(ctx).pop(true);
                    } else {
                      HapticFeedback.vibrate();
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('Cancel',
                          style: wt(Theme.of(context).textTheme.labelLarge,
                              weight: 600, color: AppColors.greyIcon)),
                    ),
                    const SizedBox(width: 10),
                    ScaleTap(
                      onTap: matches ? () => Navigator.of(ctx).pop(true) : null,
                      child: AnimatedOpacity(
                        opacity: matches ? 1 : 0.4,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.expired,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('Delete',
                              style: wt(Theme.of(context).textTheme.labelLarge,
                                  weight: 700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ).then((v) => v ?? false);
}
