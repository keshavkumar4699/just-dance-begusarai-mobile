/// Just Dance — the member card: full-width block separated by top/bottom
/// hairlines, status shown as a subtle background tint, a small square photo
/// beside the content, a bell icon for one-tap WhatsApp reminders, and an
/// action row (phone, whatsapp, renew, share … block).
/// New members get a revolving bright-color ring around the card.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/fee_engine.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/card_images.dart';
import '../../services/share_service.dart';
import '../../services/whatsapp_service.dart';
import '../student/payment_dialog.dart';
import '../student/student_detail.dart';
import 'common.dart';

class MemberCard extends StatefulWidget {
  final AppStore store;
  final Student student;
  final int staggerIndex;

  const MemberCard({
    super.key,
    required this.store,
    required this.student,
    this.staggerIndex = 0,
  });

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard>
    with SingleTickerProviderStateMixin {
  /// Revolving ring controller — plays 2 revolutions for new admissions.
  late final AnimationController _ring;
  bool _busyShare = false;

  /// Bright revolving-ring colors (gold, cyan, magenta, green).
  static const _ringColors = [
    Color(0xFFFFD700),
    Color(0xFF00E5FF),
    Color(0xFFFF2D95),
    Color(0xFF69F0AE),
    Color(0xFFFFD700),
  ];

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _maybePulse();
  }

  @override
  void didUpdateWidget(MemberCard old) {
    super.didUpdateWidget(old);
    if (old.store.pulseStudentId != widget.store.pulseStudentId) {
      _maybePulse();
    }
  }

  void _maybePulse() {
    if (widget.store.pulseStudentId == widget.student.id) {
      widget.store.pulseStudentId = 0;
      _ring.repeat(count: 2);
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  AppStore get store => widget.store;
  Student get s => widget.student;

  // ---------------- derived state ----------------

  /// The single "card status" color. PT members follow their recharge
  /// balance instead of the course plan (their fee is separate).
  Color _statusColor(AppColors c, MemberStatus ms, FeeStatus st) {
    if (s.isBlocked) return c.blocked;
    if (s.ptEnabled) {
      if (store.ptNeedsRecharge(s)) return c.expired;
      if (store.ptLowOnBalance(s)) return c.nearExpiry;
      return c.active;
    }
    return statusColor(c, ms);
  }

  /// Reminder applies when something can be nudged on WhatsApp.
  bool _canRemind(FeeStatus st, MemberStatus ms) {
    if (s.ptEnabled) {
      return store.ptNeedsRecharge(s) || store.ptLowOnBalance(s);
    }
    if (ms == MemberStatus.blocked) return false;
    return st.expired || st.daysLeft <= 7 || st.hasDue;
  }

  String _reminderMessage(FeeStatus st) {
    if (s.ptEnabled) {
      return WhatsAppService.instance.build(kTemplateFeesDue, store, s,
          due: fmtMoney(store.ptRechargeNeed(s)));
    }
    final dueText = st.hasDue ? fmtMoney(st.due) : fmtMoney(st.cyclePrice);
    return WhatsAppService.instance
        .build(kTemplateFeesDue, store, s, due: dueText);
  }

  // ---------------- actions ----------------

  Future<void> _remind(FeeStatus st) async {
    final ok =
        await WhatsAppService.instance.openChat(s.mobile, _reminderMessage(st));
    if (!ok && mounted) showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
  }

  Future<void> _shareIdCard() async {
    if (_busyShare) return;
    setState(() => _busyShare = true);
    try {
      final file = await CardImages.instance
          .generateIdCard(store: store, s: s, status: store.statusOf(s));
      final text = WhatsAppService.instance
          .build(kTemplateSendId, store, s);
      var ok = await ShareService.instance
          .imageToWhatsApp(mobile: s.mobile, imagePath: file.path, text: text);
      if (!ok) {
        // WhatsApp missing on device/number — fall back to the share sheet.
        await ShareService.instance.shareImage(file.path, text: text);
        ok = true;
      }
      if (!ok && mounted) {
        showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Could not create the ID card', duration: kSnackError);
    } finally {
      if (mounted) setState(() => _busyShare = false);
    }
  }

  Future<void> _call() async {
    final ok = await WhatsAppService.instance.call(s.mobile);
    if (!ok && mounted) showSnack(context, 'Could not open the dialer', duration: kSnackError);
  }

  Future<void> _chat() async {
    final remind = s.ptEnabled
        ? (store.ptNeedsRecharge(s) || store.ptLowOnBalance(s))
        : store.statusOf(s).hasDue;
    final msg = WhatsAppService.instance.build(
        remind ? kTemplateFeesDue : kTemplateWelcome, store, s);
    final ok = await WhatsAppService.instance.openChat(s.mobile, msg);
    if (!ok && mounted) showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
  }

  Future<void> _renew() async {
    await showPaymentDialog(context, store, s, renew: true);
  }

  Future<void> _toggleBlock() async {
    final blocking = !s.isBlocked;
    final ok = await showConfirmDialog(
      context,
      title: blocking ? 'Block ${s.name}?' : 'Unblock ${s.name}?',
      message: blocking
          ? 'Blocked members stay hidden from the Active list.'
          : 'The member returns to the normal list.',
      confirmLabel: blocking ? 'Block' : 'Unblock',
      danger: blocking,
    );
    if (ok) await store.setBlocked(s, blocking);
  }

  void _openDetail() {
    Navigator.push(
        context,
        fadeSlideRoute(
            StudentDetailScreen(store: store, studentId: s.id)));
  }

  // ---------------- build ----------------

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final st = store.statusOf(s);
    final ms = store.memberStatus(s);
    final statusCol = _statusColor(c, ms, st);

    final card = Pressable(
      onTap: _openDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(c, st, ms, statusCol),
          _contentRow(c, st),
          _actionRow(c),
        ],
      ),
    );

    return StaggerIn(
      index: widget.staggerIndex,
      child: AnimatedBuilder(
        animation: _ring,
        builder: (context, child) {
          final ringOn = _ring.isAnimating;
          final glow = ringOn
              ? (0.5 - (_ring.value - 0.5).abs()) * 2 // 0..1..0 per revolution
              : 0.0;
          final body = Container(
            // Only top + bottom hairlines separate the cards; the status is
            // a slight tint on the card background.
            decoration: BoxDecoration(
              color:
                  Color.alphaBlend(statusCol.withValues(alpha: 0.06), c.surface),
              border: Border(
                top: BorderSide(color: c.hairline),
                bottom: BorderSide(color: c.hairline),
              ),
            ),
            child: child,
          );
          if (!ringOn) return body;
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.rotate(
                angle: _ring.value * 2 * math.pi,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(colors: _ringColors),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(3),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    body,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color:
                                    statusCol.withValues(alpha: 0.28 * glow),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        child: card,
      ),
    );
  }

  Widget _header(AppColors c, FeeStatus st, MemberStatus ms, Color statusCol) {
    final plan = store.planById(s.planId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Hero(
                        tag: 'stu_name_${s.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(s.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('· ${s.jdNo}',
                        style: TextStyle(color: c.textMuted, fontSize: 12)),
                    const SizedBox(width: 8),
                    _chip(c, categoryFor(s.dob, s.gender)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    StatusDot(statusCol),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        s.ptEnabled
                            ? 'PT · ${s.mobile}'
                            : '${plan?.name ?? 'No plan'} · ${s.mobile}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bell = one-tap WhatsApp reminder (only when one applies).
          if (_canRemind(st, ms))
            Pressable(
              onTap: () => _remind(st),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.notifications_active_outlined,
                    size: 21, color: statusCol),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(AppColors c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.goldSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: c.gold, fontSize: 9.5, fontWeight: FontWeight.w700)),
    );
  }

  /// Content text on the left, small square photo on the right.
  Widget _contentRow(AppColors c, FeeStatus st) {
    final hasPhoto = s.photoPath.isNotEmpty && File(s.photoPath).existsSync();
    final left = store.ptSessionsLeft(s);
    final line1 = s.ptEnabled
        ? [
            '$left session${left == 1 ? '' : 's'} left',
            if (s.ptDays.isNotEmpty) s.ptDays,
            if (s.ptTiming.isNotEmpty) s.ptTiming,
            if (store.ptDefaultDuration.isNotEmpty) store.ptDefaultDuration,
          ].join(' · ')
        : store.primaryCourseLine(s);
    String line2;
    Color line2Color;
    if (s.ptEnabled) {
      final balance = store.ptBalanceOf(s);
      final left = store.ptSessionsLeft(s);
      if (store.ptNeedsRecharge(s)) {
        line2 = 'Recharge needed — ${fmtMoney(store.ptRechargeNeed(s))}';
        line2Color = c.expired;
      } else if (store.ptLowOnBalance(s)) {
        line2 = 'Low balance — ${fmtMoney(balance)} · $left session${left == 1 ? '' : 's'} left';
        line2Color = c.nearExpiry;
      } else {
        line2 = 'PT balance ${fmtMoney(balance)} · $left session${left == 1 ? '' : 's'} left';
        line2Color = c.active;
      }
    } else {
      line2 = 'Valid till ${fmtDate(st.paidTill)}${st.hasDue ? ' · Due ${fmtMoney(st.due)}' : ''}';
      line2Color = st.hasDue ? c.nearExpiry : c.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(line2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: line2Color, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 92,
              height: 92,
              child: hasPhoto
                  ? Image.file(File(s.photoPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(c))
                  : _photoPlaceholder(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(AppColors c) => Container(
        color: c.surface2,
        child: Center(
          child: Opacity(
            opacity: 0.5,
            child: const AppLogo(size: 44),
          ),
        ),
      );

  Widget _actionRow(AppColors c) {
    Widget action(Widget iconWidget, VoidCallback onTap,
        {bool loading = false}) {
      return Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: loading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.gold))
              : iconWidget,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      child: Row(
        children: [
          action(
              Icon(Icons.call_outlined, size: 24, color: c.textMuted),
              _call),
          action(
              WhatsAppIcon(size: 22, color: c.textMuted),
              _chat),
          action(
              Icon(Icons.autorenew_outlined, size: 24, color: c.textMuted),
              _renew),
          action(
              Icon(Icons.ios_share_outlined, size: 24, color: c.textMuted),
              _shareIdCard,
              loading: _busyShare),
          const Spacer(),
          action(
              Icon(
                  s.isBlocked
                      ? Icons.lock_open_outlined
                      : Icons.block_outlined,
                  size: 24,
                  color: c.textMuted),
              _toggleBlock),
        ],
      ),
    );
  }
}
