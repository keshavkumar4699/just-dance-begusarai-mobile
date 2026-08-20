/// Just Dance — STUDENT DETAIL: live ID card on top (black + gold), grouped
/// info, realtime ledger table, dues + attendance summary, all actions.
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/card_images.dart';
import '../../services/share_service.dart';
import '../../services/whatsapp_service.dart';
import '../add/add_member_flow.dart';
import '../home/pt_screen.dart';
import '../widgets/common.dart';
import 'delete_flow.dart';
import 'payment_dialog.dart';

class StudentDetailScreen extends StatelessWidget {
  final AppStore store;
  final int studentId;
  const StudentDetailScreen(
      {super.key, required this.store, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final idx = store.students.indexWhere((e) => e.id == studentId);
        if (idx < 0) {
          // Student was deleted — close the detail screen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
          return const Scaffold();
        }
        final s = store.students[idx];
        return Scaffold(
          appBar: AppBar(
            title: Text(s.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    showAddMemberFlow(context, store, existing: s),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _IdCardView(store: store, s: s),
              const SizedBox(height: 16),
              _actions(context, store, s),
              const SizedBox(height: 20),
              _duesSummary(context, store, s),
              const SizedBox(height: 20),
              _infoGroups(context, store, s),
              const SizedBox(height: 20),
              _ptSection(context, store, s),
              const SizedBox(height: 20),
              _attendanceSummary(context, store, s),
              const SizedBox(height: 20),
              _ledgerTable(context, store, s),
            ],
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, AppStore store, Student s) {
    final present = store.isPresentToday(s);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GoldButton('Payment',
                  icon: Icons.currency_rupee,
                  onTap: () => showPaymentDialog(context, store, s)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GhostButton('Renew',
                  icon: Icons.autorenew_outlined,
                  onTap: () =>
                      showPaymentDialog(context, store, s, renew: true)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GhostButton(
                present ? 'Present ✔' : 'Present',
                icon: present
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: present ? AppColors.of(context).active : null,
                onTap: present
                    ? null
                    : () async {
                        await store.markPresent(s);
                        if (context.mounted) {
                          showSnack(context, '${s.name} marked present', duration: kSnackSuccess);
                        }
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GhostButton('WhatsApp',
                  leading: WhatsAppIcon(size: 17, color: AppColors.of(context).text),
                  onTap: () async {
                final st = store.statusOf(s);
                final key =
                    st.hasDue ? kTemplateFeesDue : kTemplateWelcome;
                final msg = WhatsAppService.instance.build(key, store, s,
                    due: st.hasDue
                        ? fmtMoney(st.due)
                        : fmtMoney(st.cyclePrice));
                final ok = await WhatsAppService.instance
                    .openChat(s.mobile, msg);
                if (!ok && context.mounted) {
                  showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
                }
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GhostButton('Share ID',
                  icon: Icons.ios_share_outlined,
                  onTap: () => _shareId(context, store, s)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GhostButton('Call',
                  icon: Icons.call_outlined, onTap: () async {
                final ok = await WhatsAppService.instance.call(s.mobile);
                if (!ok && context.mounted) {
                  showSnack(context, 'Could not open the dialer', duration: kSnackError);
                }
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                s.ptEnabled ? 'Switch to Course' : 'Add to Personal Training',
                icon: Icons.fitness_center_outlined,
                onTap: () {
                  if (s.ptEnabled) {
                    showSwitchToCourseSheet(context, store, s);
                  } else {
                    showSwitchToPtSheet(context, store, s);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                s.isBlocked ? 'Unblock' : 'Block',
                icon: s.isBlocked
                    ? Icons.lock_open_outlined
                    : Icons.block_outlined,
                onTap: () async {
                  final blocking = !s.isBlocked;
                  final ok = await showConfirmDialog(context,
                      title: blocking ? 'Block ${s.name}?' : 'Unblock ${s.name}?',
                      message: blocking
                          ? 'Blocked members stay hidden from the Active list.'
                          : 'The member returns to the normal list.',
                      confirmLabel: blocking ? 'Block' : 'Unblock',
                      danger: blocking);
                  if (ok) await store.setBlocked(s, blocking);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GhostButton('Delete',
                  icon: Icons.delete_outline,
                  color: AppColors.of(context).expired,
                  onTap: () =>
                      confirmAndDeleteStudent(context, store, s)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareId(BuildContext context, AppStore store, Student s) async {
    try {
      final file = await CardImages.instance
          .generateIdCard(store: store, s: s, status: store.statusOf(s));
      final text =
          WhatsAppService.instance.build(kTemplateSendId, store, s);
      var ok = await ShareService.instance
          .imageToWhatsApp(mobile: s.mobile, imagePath: file.path, text: text);
      if (!ok) {
        await ShareService.instance.shareImage(file.path, text: text);
        ok = true;
      }
      if (!ok && context.mounted) {
        showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
      }
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not create the ID card', duration: kSnackError);
    }
  }

  Widget _duesSummary(BuildContext context, AppStore store, Student s) {
    final c = AppColors.of(context);
    final st = store.statusOf(s);
    Widget item(String label, String value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          item('Due', fmtMoney(st.due),
              st.hasDue ? c.expired : c.active),
          Container(width: 1, height: 30, color: c.hairline),
          item('Advance', fmtMoney(st.advance), c.gold),
          Container(width: 1, height: 30, color: c.hairline),
          item('Monthly', fmtMoney(st.cyclePrice), c.text),
          Container(width: 1, height: 30, color: c.hairline),
          item('Paid till', fmtDate(st.paidTill), c.text),
        ],
      ),
    );
  }

  Widget _infoGroups(BuildContext context, AppStore store, Student s) {
    final c = AppColors.of(context);
    final courses = store.coursesOf(s.id);
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 130,
                  child: Text(k,
                      style:
                          TextStyle(color: c.textMuted, fontSize: 12.5))),
              Expanded(
                  child: Text(v.isEmpty ? '—' : v,
                      style: const TextStyle(fontSize: 13.5))),
            ],
          ),
        );

    Widget group(String title, List<Widget> rows) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(title),
              const SizedBox(height: 6),
              ...rows,
            ],
          ),
        );

    final perm = [s.permVillage, s.permPO, s.permDist, s.permPin]
        .where((e) => e.isNotEmpty)
        .join(', ');
    final corr = s.corrSame
        ? perm
        : [s.corrVillage, s.corrPO, s.corrDist, s.corrPin]
            .where((e) => e.isNotEmpty)
            .join(', ');

    return Column(
      children: [
        group('Personal Details', [
          row('Name', s.name),
          row("Father's Name", s.fatherName),
          row("Mother's Name", s.motherName),
          row('Mobile', s.mobile),
          row('Alt Mobile', s.altMobile),
          row('Permanent Addr.', perm),
          row('Corr. Addr.', corr),
        ]),
        group('Identity & Personal Info', [
          row('Aadhar', s.aadhar),
          row('Date of Birth',
              s.dob == null ? '' : fmtDate(s.dob, forceYear: true)),
          row('Gender', s.gender),
          row('Category', categoryFor(s.dob, s.gender)),
          row('Religion', s.religion),
          row('Nationality', s.nationality),
          row('Marital Status', s.maritalStatus),
        ]),
        group('Courses & Batch', [
          if (courses.isEmpty) row('Course', '—'),
          for (final sc in courses)
            row(
              sc.isPrimary ? 'Primary' : 'Course',
              [
                store.courseById(sc.courseId)?.name ?? '—',
                store.batchById(sc.batchId)?.name ?? '',
                store.timingById(sc.timingId)?.label ?? '',
              ].where((e) => e.isNotEmpty).join(' · '),
            ),
          row('Plan', store.planById(s.planId)?.name ?? '—'),
          row('Joining Date', fmtDate(s.admissionDate, forceYear: true)),
          row('Expiration Date',
              fmtDate(store.statusOf(s).paidTill, forceYear: true)),
          if (s.admissionFeeEnabled)
            row('Admission Fee',
                s.admissionFeePaid ? 'Paid' : 'Due ${fmtMoney(store.admissionFeeAmount)}'),
        ]),
      ],
    );
  }

  Widget _ptSection(BuildContext context, AppStore store, Student s) {
    if (!s.ptEnabled) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final balance = store.ptBalanceOf(s);
    final left = store.ptSessionsLeft(s);
    final low = store.ptLowOnBalance(s);
    final need = store.ptNeedsRecharge(s);
    final (statusText, statusColor) = need
        ? ('Recharge needed — ${fmtMoney(store.ptRechargeNeed(s))}', c.expired)
        : low
            ? ('Low balance — ${fmtMoney(balance)} · $left session${left == 1 ? '' : 's'} left', c.nearExpiry)
            : ('Balance ${fmtMoney(balance)} · $left session${left == 1 ? '' : 's'} left', c.active);
    final meta = [
      if (s.ptDays.isNotEmpty) s.ptDays,
      if (s.ptTiming.isNotEmpty) s.ptTiming,
      if (store.ptDefaultDuration.isNotEmpty) store.ptDefaultDuration,
    ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Personal Training',
              trailing: TextButton.icon(
                onPressed: () => showPtEditSheet(context, store, s),
                icon: Icon(Icons.edit_outlined, color: c.gold, size: 16),
                label: Text('Edit',
                    style: TextStyle(color: c.gold, fontSize: 12)),
              )),
          const SizedBox(height: 4),
          Text(
              '${s.ptSessionsDone} done · ${fmtMoney(s.ptSessionPrice)}/session'
              '${meta.isEmpty ? '' : ' · $meta'}',
              style: const TextStyle(fontSize: 13.5)),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _attendanceSummary(BuildContext context, AppStore store, Student s) {
    final c = AppColors.of(context);
    final rows = store.attendanceOf(s.id);
    final total = rows.length;
    final last = s.lastVisitDate;
    final expected =
        daysBetween(s.admissionDate, DateTime.now()) + 1;
    final rate = expected <= 0 ? 0 : (total / expected * 100).clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _miniStat(context, 'Last visit', last == null ? 'Never' : fmtDate(last)),
          _miniStat(context, 'Total present', '$total'),
          _miniStat(context, 'Rate', '${rate.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String k, String v) => Column(
        children: [
          Text(k.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );

  Widget _ledgerTable(BuildContext context, AppStore store, Student s) {
    final c = AppColors.of(context);
    final entries = store.ledgerOf(s.id)
      ..sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        return cmp != 0 ? cmp : b.id.compareTo(a.id);
      });
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Payment History'),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text('No payments yet',
                style: TextStyle(color: c.textMuted, fontSize: 13))
          else
            for (final e in entries) ...[
              _ledgerRow(context, e),
              Divider(color: c.hairline, height: 14),
            ],
        ],
      ),
    );
  }

  Widget _ledgerRow(BuildContext context, LedgerEntry e) {
    final c = AppColors.of(context);
    final particulars = switch (e.type) {
      kLedgerPayment => 'Plan payment',
      kLedgerAdmissionFee => 'Admission fee',
      kLedgerAutoCredit => 'Advance adjusted',
      kLedgerPtPayment => 'PT payment',
      kLedgerPlanChange => 'Plan change',
      _ => 'Note',
    };
    final bal = e.balanceOrCredit;
    final balText = bal > 0.004
        ? 'Baki ${fmtMoney(bal)}'
        : bal < -0.004
            ? 'Adv ${fmtMoney(-bal)}'
            : 'Settled';
    final balColor =
        bal > 0.004 ? c.expired : (bal < -0.004 ? c.gold : c.active);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(particulars,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                  '${fmtDate(e.date, forceYear: true)} · ${e.monthLabel}${e.mode.isEmpty ? '' : ' · ${e.mode}'}',
                  style: TextStyle(color: c.textMuted, fontSize: 11)),
              if (e.note.isNotEmpty)
                Text(e.note,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (e.paidAmount > 0)
                Text(fmtMoney(e.paidAmount),
                    style: TextStyle(
                        color: c.active,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              if (e.discount > 0)
                Text('Disc ${fmtMoney(e.discount)}',
                    style: TextStyle(color: c.gold, fontSize: 11)),
              if (e.type == kLedgerPayment || e.type == kLedgerAdmissionFee)
                Text(balText,
                    style: TextStyle(
                        color: balColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The on-screen ID card (mirrors the shareable JPG).
class _IdCardView extends StatelessWidget {
  final AppStore store;
  final Student s;
  const _IdCardView({required this.store, required this.s});

  @override
  Widget build(BuildContext context) {
    final st = store.statusOf(s);
    final plan = store.planById(s.planId);
    const gold = Color(0xFFC8A24A);
    final statusColor = st.hasDue
        ? const Color(0xFFE5484D)
        : (st.daysLeft <= 7 ? const Color(0xFFFFB224) : const Color(0xFF46A758));
    final statusText = st.hasDue
        ? (st.daysLeft <= 7 && !st.expired
            ? '${fmtMoney(st.due)} DUE'
            : 'FEES DUE ${fmtMoney(st.due)}')
        : (st.advance > 0
            ? 'FEES PAID ✔ (+Advance ${fmtMoney(st.advance)})'
            : 'FEES PAID ✔');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold, width: 1.4),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'stu_photo_${s.id}',
                child: SquircleAvatar(
                    photoPath: s.photoPath, name: s.name, size: 72, radius: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'stu_name_${s.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(s.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFF5F1E8),
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${s.jdNo} · ${categoryFor(s.dob, s.gender)}',
                        style: const TextStyle(
                            color: gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(s.mobile,
                        style: const TextStyle(
                            color: Color(0xFF8B8B93), fontSize: 12)),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.9,
                child: AppLogo(size: 44),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0x29FFFFFF)),
          const SizedBox(height: 12),
          _line('Course', store.primaryCourseLine(s)),
          _line('Plan', plan?.name ?? '—'),
          _line('Valid Till', fmtDate(st.paidTill, forceYear: true)),
          if (s.fatherName.isNotEmpty) _line("Father's Name", s.fatherName),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(k.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF8B8B93),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2)),
            ),
            Expanded(
              child: Text(v,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFFF5F1E8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
