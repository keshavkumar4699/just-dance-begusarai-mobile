import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import 'common.dart';
import 'slide_present_slider.dart';

/// Instagram-post-style member card for Home and PT screens.
class MemberCard extends StatelessWidget {
  final Student student;
  final StudentStatus status;
  final String courseLine;
  final String planName;
  final VoidCallback onTap;
  final Future<bool> Function() onMarkPresent;
  final VoidCallback onShare;
  final VoidCallback onCall;
  final VoidCallback onRenew;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;
  final VoidCallback onReminder;

  /// Staggered entrance index (50ms apart, first build only).
  final int entranceIndex;

  /// Optional override for the content line (PT screen shows sessions info).
  final String? contentLineOverride;

  /// True when another student shares this mobile (non-blocking warning).
  final bool duplicateMobile;

  const MemberCard({
    super.key,
    required this.student,
    required this.status,
    required this.courseLine,
    required this.planName,
    required this.onTap,
    required this.onMarkPresent,
    required this.onShare,
    required this.onCall,
    required this.onRenew,
    required this.onToggleBlock,
    required this.onDelete,
    required this.onReminder,
    this.entranceIndex = 0,
    this.contentLineOverride,
    this.duplicateMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final statusColor = status.status.color;
    final jdNo = student.jdNo;

    String contentLine2;
    if (status.status == MemberStatus.expired) {
      contentLine2 = 'Expired ${status.daysOverdue} days ago';
    } else if (status.status == MemberStatus.due) {
      contentLine2 = 'Admission fee due ${Money.fmt(status.admissionFeeDue)}';
    } else if (status.paidTill != null) {
      contentLine2 = 'Valid till ${Dates.display(Dates.fmt(status.paidTill!))}';
    } else {
      contentLine2 = 'Joined ${Dates.display(student.admissionDate)}';
    }

    return _Entrance(
      index: entranceIndex,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Header row ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Avatar(photoPath: student.photoPath, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                student.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: wt(Theme.of(context).textTheme.titleMedium, weight: 700),
                              ),
                            ),
                            if (student.isBlocked) ...[
                              const SizedBox(width: 6),
                              const Text('🚫', style: TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              jdNo,
                              style: wt(Theme.of(context).textTheme.labelSmall,
                                  weight: 700, color: AppColors.gold),
                            ),
                            if (_category().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _miniChip(_category()),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status dot + text.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status.status.label.toUpperCase(),
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 700, color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ---- Photo area (full width) ----
            AspectRatio(
              aspectRatio: 1.9,
              child: student.photoPath.isNotEmpty
                  ? Image.file(FileImageSafe.file(student.photoPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset('assets/images/placeholder.png',
                          fit: BoxFit.cover, width: double.infinity))
                  : Image.asset('assets/images/placeholder.png',
                      fit: BoxFit.cover, width: double.infinity),
            ),
            // ---- Content row ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contentLineOverride ??
                        (courseLine.isEmpty ? 'No course assigned' : courseLine),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wt(Theme.of(context).textTheme.bodyMedium, weight: 600),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contentLine2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: wt(Theme.of(context).textTheme.bodySmall,
                              weight: 500,
                              color: status.status == MemberStatus.expired
                                  ? AppColors.expired
                                  : AppColors.greyIcon),
                        ),
                      ),
                      if (planName.isNotEmpty)
                        Text(
                          planName,
                          style: wt(Theme.of(context).textTheme.labelSmall,
                              weight: 700, color: AppColors.greyIcon),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // ---- Slide-to-mark-present ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SlidePresentSlider(onComplete: onMarkPresent),
            ),
            // Duplicate mobile warning (non-blocking).
            if (duplicateMobile)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.nearExpiry),
                    const SizedBox(width: 6),
                    Text('Another member has this mobile',
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 600, color: AppColors.nearExpiry)),
                  ],
                ),
              ),
            // ---- Integrated status strip (before action row) ----
            _StatusStrip(student: student, status: status, onReminder: onReminder),
            // ---- Action row ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Action(icon: Icons.ios_share_outlined, label: 'Share', onTap: onShare),
                  _Action(icon: Icons.call_outlined, label: 'Call', onTap: onCall),
                  _Action(icon: Icons.autorenew, label: 'Renew', onTap: onRenew),
                  _Action(
                    icon: student.isBlocked ? Icons.block : Icons.block_outlined,
                    label: student.isBlocked ? 'Unblock' : 'Block',
                    onTap: onToggleBlock,
                  ),
                  _Action(icon: Icons.delete_outline, label: 'Delete', onTap: onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _category() {
    if (student.dob.isEmpty) return '';
    return categoryFor(dob: Dates.parse(student.dob));
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text,
          style: wt(null, weight: 700, size: 8.5, color: AppColors.gold)),
    );
  }
}

/// The integrated status strip: gold-warning near expiry, red expired,
/// subtle hairline otherwise.
class _StatusStrip extends StatelessWidget {
  final Student student;
  final StudentStatus status;
  final VoidCallback onReminder;

  const _StatusStrip({required this.student, required this.status, required this.onReminder});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    String? text;
    Color? color;
    VoidCallback? action;

    if (student.isBlocked) {
      text = 'Blocked';
      color = AppColors.blocked;
    } else if (status.status == MemberStatus.expired) {
      text = 'Expired ${status.daysOverdue} days ago - Renew now';
      color = AppColors.expired;
      action = onReminder;
    } else if (status.status == MemberStatus.due) {
      text = 'Admission fee due ${Money.fmt(status.admissionFeeDue)} - Collect';
      color = AppColors.nearExpiry;
      action = onReminder;
    } else if (status.daysLeft <= 7 && status.paidTill != null) {
      text = status.daysLeft == 0
          ? 'Plan ends today - send WhatsApp reminder'
          : 'Plan ends in ${status.daysLeft} day${status.daysLeft == 1 ? '' : 's'} - send WhatsApp reminder';
      color = AppColors.nearExpiry;
      action = onReminder;
    } else {
      text = status.paidTill != null
          ? 'Plan ends in ${status.daysLeft} day${status.daysLeft == 1 ? '' : 's'}'
          : 'Active';
      color = AppColors.greyIcon;
    }

    final soft = color.withValues(alpha: 0.10);
    final content = Row(
      children: [
        Icon(
          color == AppColors.greyIcon ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: wt(Theme.of(context).textTheme.labelMedium, weight: 600, color: color),
          ),
        ),
        if (action != null) ...[
          Icon(Icons.chevron_right, size: 16, color: color),
        ],
      ],
    );

    return InkWell(
      onTap: action,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            top: BorderSide(color: color.withValues(alpha: dark ? 0.25 : 0.2)),
            bottom: BorderSide(color: color.withValues(alpha: dark ? 0.25 : 0.2)),
          ),
        ),
        child: content,
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: AppColors.greyIcon),
            const SizedBox(height: 2),
            Text(
              label,
              style: wt(Theme.of(context).textTheme.labelSmall,
                  weight: 600, color: AppColors.greyIcon),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered entrance: fade + 6dp slide, 50ms apart, first build only.
class _Entrance extends StatefulWidget {
  final int index;
  final Widget child;

  const _Entrance({required this.index, required this.child});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
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
    final t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(t),
        child: widget.child,
      ),
    );
  }
}

