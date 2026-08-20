/// Just Dance — shared building blocks (Instagram-like, hairline-first).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/store.dart';

// ---------------- labels & chips ----------------

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  const StatusDot(this.color, {super.key, this.size = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

Color statusColor(AppColors c, MemberStatus s) => switch (s) {
      MemberStatus.active => c.active,
      MemberStatus.nearExpiry => c.nearExpiry,
      MemberStatus.expired => c.expired,
      MemberStatus.inactive => c.inactive,
      MemberStatus.blocked => c.blocked,
    };

String statusLabel(MemberStatus s) => switch (s) {
      MemberStatus.active => 'Active',
      MemberStatus.nearExpiry => 'Ending soon',
      MemberStatus.expired => 'Expired',
      MemberStatus.inactive => 'Inactive',
      MemberStatus.blocked => 'Blocked 🚫',
    };

// ---------------- buttons ----------------

/// The WhatsApp logo (assets/icon_whatsapp.svg), tinted to fit any surface.
class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;
  const WhatsAppIcon({super.key, this.size = 18, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icon_whatsapp.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? leading; // custom leading widget (e.g. WhatsAppIcon)
  final bool expand;
  const GoldButton(this.label,
      {super.key, this.onTap, this.icon, this.leading, this.expand = true});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: onTap == null ? c.gold.withValues(alpha: 0.4) : c.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null || icon != null) ...[
              if (leading != null)
                leading!
              else
                Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? leading; // custom leading widget (e.g. WhatsAppIcon)
  final Color? color;
  const GhostButton(this.label,
      {super.key, this.onTap, this.icon, this.leading, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final col = color ?? c.text;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null || icon != null) ...[
              if (leading != null)
                leading!
              else
                Icon(icon, size: 17, color: col),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: col, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- avatar ----------------

/// The Just Dance logo with slightly rounded corners (brand-wide standard).
class AppLogo extends StatelessWidget {
  final double size;
  final double? radius;
  const AppLogo({super.key, this.size = 44, this.radius});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size * 0.16),
        child: Image.asset('assets/logo.png',
            width: size, height: size, fit: BoxFit.cover),
      );
}

class SquircleAvatar extends StatelessWidget {
  final String photoPath;
  final String name;
  final double size;
  final double radius;
  const SquircleAvatar({
    super.key,
    required this.photoPath,
    required this.name,
    this.size = 44,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasPhoto =
        photoPath.isNotEmpty && File(photoPath).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: c.surface2,
        child: hasPhoto
            ? Image.file(File(photoPath), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(c))
            : _placeholder(c),
      ),
    );
  }

  Widget _placeholder(AppColors c) => Center(
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(
              color: c.gold,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.4),
        ),
      );
}

// ---------------- empty state ----------------

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  const EmptyState({super.key, required this.icon, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.hairline, width: 1.5)),
              child: Icon(icon, color: c.textMuted, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- sheets & dialogs ----------------

/// Bottom sheet with scale-in 0.94 -> 1.0 + fade 180ms.
Future<T?> showAppSheet<T>(BuildContext context, Widget child,
    {bool isScrollControlled = true, bool isDismissible = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final c = AppColors.of(ctx);
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: Motion.fast,
        curve: Motion.curve,
        builder: (_, v, child) => FadeTransition(
          opacity: AlwaysStoppedAnimation(v.clamp(0.0, 1.0)),
          child: Transform.scale(scale: v, child: child),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.of(ctx).surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: c.hairline)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: child,
          ),
        ),
      );
    },
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Yes',
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final c = AppColors.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel,
                style: TextStyle(color: c.textMuted))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: danger ? c.expired : c.gold,
                    fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message,
    {SnackBarAction? action, Duration? duration}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: action,
      duration: duration ?? kSnackWarn,
    ));
}

/// Snackbar timings: quick success feedback, normal info, validation hints,
/// errors with a moment to read, and long-running messages with actions.
const kSnackSuccess = Duration(seconds: 2);
const kSnackInfo = Duration(seconds: 3);
const kSnackWarn = Duration(seconds: 4);
const kSnackError = Duration(seconds: 6);
const kSnackLong = Duration(seconds: 8);
const kSnackBackup = Duration(seconds: 4);

// ---------------- form helpers ----------------

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 16),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

class DateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime> onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;
  const DateField({
    super.key,
    required this.value,
    required this.hint,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(1920),
          lastDate: lastDate ?? DateTime(now.year + 5),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, size: 18, color: c.textMuted),
            const SizedBox(width: 10),
            Text(
              value == null ? hint : _fmt(value!),
              style: TextStyle(
                  color: value == null ? c.textMuted : c.text, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Simple dropdown row styled like the text fields.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const AppDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: c.textMuted, fontSize: 14)),
          isExpanded: true,
          dropdownColor: c.surface,
          icon: Icon(Icons.keyboard_arrow_down, color: c.textMuted),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
