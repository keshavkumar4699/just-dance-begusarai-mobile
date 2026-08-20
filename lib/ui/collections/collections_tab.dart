/// Just Dance — TAB 4: COLLECTIONS.
/// [Month] [Year] [All Time] segments; Admission vs Membership fee cards,
/// PT card when PT payments exist, recent entries with count-up.
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';

class CollectionsTab extends StatefulWidget {
  final AppStore store;
  const CollectionsTab({super.key, required this.store});

  @override
  State<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends State<CollectionsTab> {
  int _segment = 0; // 0 month, 1 year, 2 all

  AppStore get store => widget.store;

  bool _inRange(LedgerEntry e) {
    final now = DateTime.now();
    switch (_segment) {
      case 0:
        return e.date.year == now.year && e.date.month == now.month;
      case 1:
        return e.date.year == now.year;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entries = store.ledger.where(_inRange).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double sumOf(String type) => entries
        .where((e) => e.type == type)
        .fold(0.0, (a, e) => a + e.paidAmount);
    int countOf(String type) => entries.where((e) => e.type == type).length;

    final admission = sumOf(kLedgerAdmissionFee);
    final membership = sumOf(kLedgerPayment);
    final pt = sumOf(kLedgerPtPayment);
    // Outstanding PT recharge need across every PT member (their fee is
    // separate — a prepaid session balance).
    final ptDue = store.students
        .where((s) => s.ptEnabled && !s.isBlocked)
        .fold(0.0, (a, s) {
      final d = store.ptRechargeNeed(s);
      return a + d;
    });
    final ptDueMembers = store.students
        .where((s) => s.ptEnabled && !s.isBlocked && store.ptLowOnBalance(s))
        .length;
    final moneyEntries = entries
        .where((e) =>
            e.paidAmount > 0 &&
            (e.type == kLedgerPayment ||
                e.type == kLedgerAdmissionFee ||
                e.type == kLedgerPtPayment))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        children: [
          _segmented(c),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _moneyCard(c, 'Admission Fee Collection',
                      admission, countOf(kLedgerAdmissionFee), Icons.badge_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: _moneyCard(c, 'Membership Fee Collection',
                      membership, countOf(kLedgerPayment), Icons.card_membership_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          _moneyCard(c, 'Personal Training', pt, countOf(kLedgerPtPayment),
              Icons.fitness_center_outlined,
              wide: true,
              extra: ptDueMembers > 0
                  ? 'Low balance: $ptDueMembers member${ptDueMembers == 1 ? '' : 's'} · recharge ${fmtMoney(ptDue)}'
                  : null),
          const SizedBox(height: 20),
          SectionLabel('Recent entries (${moneyEntries.length})'),
          const SizedBox(height: 10),
          if (moneyEntries.isEmpty)
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No collections yet',
              hint: _segment == 0
                  ? 'Nothing collected this month. Try Year or All Time.'
                  : 'Payments you record will show up here.',
            )
          else
            for (var i = 0; i < moneyEntries.length; i++)
              _entryRow(c, moneyEntries[i], i),
        ],
      ),
    );
  }

  Widget _segmented(AppColors c) {
    const labels = ['Month', 'Year', 'All Time'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Pressable(
                onTap: () => setState(() => _segment = i),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _segment == i ? c.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _segment == i ? Colors.black : c.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _moneyCard(AppColors c, String title, double total, int count,
      IconData icon,
      {bool wide = false, String? extra}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CountUpText(
            total,
            formatter: (v) => fmtMoney(v),
            style: TextStyle(
                color: c.gold, fontWeight: FontWeight.w800, fontSize: 21),
          ),
          const SizedBox(height: 2),
          Text('$count payment${count == 1 ? '' : 's'}',
              style: TextStyle(color: c.textMuted, fontSize: 11.5)),
          if (extra != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.nearExpiry.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(extra,
                    style: TextStyle(
                        color: c.nearExpiry,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryRow(AppColors c, LedgerEntry e, int index) {
    final s = store.students.where((x) => x.id == e.studentId).firstOrNull;
    final typeLabel = switch (e.type) {
      kLedgerAdmissionFee => 'Admission',
      kLedgerPtPayment => 'PT',
      _ => 'Plan',
    };
    return StaggerIn(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.goldSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(typeLabel,
                  style: TextStyle(
                      color: c.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s?.name ?? 'Deleted member',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                      '${fmtDate(e.date, forceYear: true)}${e.mode.isEmpty ? '' : ' · ${e.mode}'}',
                      style: TextStyle(color: c.textMuted, fontSize: 11)),
                ],
              ),
            ),
            CountUpText(
              e.paidAmount,
              formatter: (v) => '+${fmtMoney(v)}',
              style: TextStyle(
                  color: c.active, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
