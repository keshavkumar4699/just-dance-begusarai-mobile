import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';

/// TAB 4 - COLLECTIONS: month/year/all segments, admission vs membership
/// totals, PT card when PT payments exist, recent entries with count-up.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

enum _Segment { month, year, all }

class _CollectionsScreenState extends State<CollectionsScreen> {
  _Segment _segment = _Segment.month;
  int _monthOffset = 0;
  int _yearOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return SafeArea(
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final now = DateTime.now();
          final selMonth = DateTime(now.year, now.month + _monthOffset);
          final selYear = now.year + _yearOffset;

          bool Function(String) inRange;
          String label;
          switch (_segment) {
            case _Segment.month:
              label = '${selMonth.year}-${selMonth.month.toString().padLeft(2, '0')}';
              inRange = (d) {
                final dt = Dates.parse(d);
                return dt.year == selMonth.year && dt.month == selMonth.month;
              };
            case _Segment.year:
              label = '$selYear';
              inRange = (d) => Dates.parse(d).year == selYear;
            case _Segment.all:
              label = 'All time';
              inRange = (d) => true;
          }

          var admissionTotal = 0;
          var membershipTotal = 0;
          var ptTotal = 0;
          var admissionCount = 0;
          var membershipCount = 0;
          final recent = <LedgerEntry>[];

          for (final e in state.ledger) {
            if (!inRange(e.date)) continue;
            if (e.paidAmount <= 0) continue;
            switch (e.type) {
              case LedgerType.admissionFeePaid:
                admissionTotal += e.paidAmount;
                admissionCount++;
                recent.add(e);
              case LedgerType.payment:
                membershipTotal += e.paidAmount;
                membershipCount++;
                recent.add(e);
              case LedgerType.ptPayment:
                ptTotal += e.paidAmount;
                recent.add(e);
              case LedgerType.autoCreditAdjust:
                membershipTotal += e.paidAmount;
                recent.add(e);
              default:
                break;
            }
          }
          recent.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  children: [
                    Text('Collections',
                        style: wt(Theme.of(context).textTheme.titleLarge, weight: 800)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.greyIcon),
                      onPressed: () => setState(() {
                        if (_segment == _Segment.month) {
                          _monthOffset--;
                        } else if (_segment == _Segment.year) {
                          _yearOffset--;
                        }
                      }),
                    ),
                    Text(label,
                        style: wt(Theme.of(context).textTheme.labelMedium,
                            weight: 700, color: AppColors.gold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 22, color: AppColors.greyIcon),
                      onPressed: () => setState(() {
                        if (_segment == _Segment.month) {
                          _monthOffset++;
                        } else if (_segment == _Segment.year) {
                          _yearOffset++;
                        }
                      }),
                    ),
                  ],
                ),
              ),
              // Segments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<_Segment>(
                  segments: const [
                    ButtonSegment(value: _Segment.month, label: Text('Month')),
                    ButtonSegment(value: _Segment.year, label: Text('Year')),
                    ButtonSegment(value: _Segment.all, label: Text('All Time')),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (s) => setState(() => _segment = s.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedForegroundColor: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Main cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _bigCard(
                        'Admission Fee',
                        admissionTotal,
                        '$admissionCount paid',
                        Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _bigCard(
                        'Membership Fee',
                        membershipTotal,
                        '$membershipCount payments',
                        Icons.wallet_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              if (ptTotal > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: _bigCard(
                    'Personal Training',
                    ptTotal,
                    'PT payments',
                    Icons.fitness_center_outlined,
                    small: true,
                  ),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionLabel('RECENT ENTRIES'),
              ),
              Expanded(
                child: recent.isEmpty
                    ? const EmptyState(
                        message: 'No collections yet', icon: Icons.account_balance_wallet_outlined)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                        itemCount: recent.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = recent[i];
                          return _entryRow(e);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bigCard(String label, int total, String sub, IconData icon, {bool small = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(small ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: small ? 17 : 20, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wt(Theme.of(context).textTheme.labelSmall,
                        weight: 700, color: AppColors.greyIcon)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CountUpText(total,
              style: wt(Theme.of(context).textTheme.titleLarge,
                  weight: 800, color: scheme.onSurface)),
          Text(sub,
              style: wt(Theme.of(context).textTheme.labelSmall,
                  weight: 500, color: AppColors.greyIcon)),
        ],
      ),
    );
  }

  Widget _entryRow(LedgerEntry e) {
    final state = AppState.instance;
    final s = state.studentById(e.studentId);
    final scheme = Theme.of(context).colorScheme;
    final typeLabel = switch (e.type) {
      LedgerType.admissionFeePaid => 'Admission',
      LedgerType.payment => 'Membership',
      LedgerType.autoCreditAdjust => 'Advance',
      LedgerType.ptPayment => 'PT',
      _ => e.type,
    };
    final typeColor = switch (e.type) {
      LedgerType.admissionFeePaid => AppColors.nearExpiry,
      LedgerType.payment => AppColors.active,
      LedgerType.autoCreditAdjust => AppColors.inactive,
      LedgerType.ptPayment => AppColors.gold,
      _ => AppColors.greyIcon,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              e.type == LedgerType.admissionFeePaid
                  ? Icons.badge_outlined
                  : e.type == LedgerType.ptPayment
                      ? Icons.fitness_center_outlined
                      : Icons.payments_outlined,
              size: 17,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s?.name ?? 'Member ${e.studentId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: wt(Theme.of(context).textTheme.titleSmall, weight: 700),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(typeLabel,
                          style: wt(Theme.of(context).textTheme.labelSmall,
                              weight: 700, color: typeColor)),
                    ),
                    const SizedBox(width: 6),
                    Text(Dates.displayShort(e.date),
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 500, color: AppColors.greyIcon)),
                    const SizedBox(width: 6),
                    Text(e.mode.isEmpty ? '' : e.mode,
                        style: wt(Theme.of(context).textTheme.labelSmall,
                            weight: 500, color: AppColors.greyIcon)),
                  ],
                ),
              ],
            ),
          ),
          CountUpText(e.paidAmount,
              style: wt(Theme.of(context).textTheme.titleSmall,
                  weight: 800, color: AppColors.gold)),
        ],
      ),
    );
  }
}
