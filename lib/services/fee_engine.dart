import '../constants.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';

/// Fee Engine v2 - ledger-based, realtime, pure Dart.
///
/// Everything here is deterministic: given the same admission date, cycle
/// price and ledger, the numbers are identical. Statuses are NEVER stored.
///
/// Core rules:
///  - monthsCovered = floor(membershipValuePaid / cyclePrice)
///  - paidTill = addMonths(admissionDate, monthsCovered) (calendar-safe)
///  - engineDue = months elapsed past paidTill x cyclePrice (0 while today <= paidTill)
///  - overpay -> credit (advance). credit auto-consumes a cycle when due exists.
///  - admission fee is a separate due when enabled and unpaid.
class FeeEngine {
  /// Discount math. [type] is '₹' or '%'. Percent is capped 0-100.
  static int applyDiscount(int base, String type, int value) {
    if (base <= 0 || value <= 0) return 0;
    if (type == '%') {
      final v = value.clamp(0, 100);
      return (base * v / 100).round();
    }
    return value > base ? base : value;
  }

  /// Full months between two dates (negative when [to] is before [from]).
  static int monthsBetween(DateTime from, DateTime to) => Dates.monthsBetween(from, to);

  /// Calendar-safe month addition (Jan 31 + 1mo = Feb 28).
  static DateTime addMonths(DateTime d, int months) => Dates.addMonths(d, months);

  /// Replays the ledger to compute credit (advance) state.
  ///
  /// PAYMENT entries add their positive balance (advance).
  /// AUTO_CREDIT_ADJUST entries consume credit by their paidAmount.
  static int replayCredit(List<LedgerEntry> ledger) {
    var credit = 0;
    for (final e in ledger) {
      if (e.type == LedgerType.payment) {
        credit += e.balanceOrCredit > 0 ? e.balanceOrCredit : 0;
      } else if (e.type == LedgerType.autoCreditAdjust) {
        credit -= e.paidAmount;
        if (credit < 0) credit = 0;
      }
    }
    return credit;
  }

  /// Total value put into membership cycles (cash payments + credit consumption).
  static int replayMembershipPaid(List<LedgerEntry> ledger) {
    var total = 0;
    for (final e in ledger) {
      if (e.type == LedgerType.payment || e.type == LedgerType.autoCreditAdjust) {
        total += e.paidAmount;
      }
    }
    return total;
  }

  /// Total PT payments.
  static int replayPtPaid(List<LedgerEntry> ledger) {
    var total = 0;
    for (final e in ledger) {
      if (e.type == LedgerType.ptPayment) total += e.paidAmount;
    }
    return total;
  }

  /// Core computation for one student.
  static StudentStatus computeStatus({
    required int cyclePrice,
    required String admissionDate,
    required String today,
    required List<LedgerEntry> ledger,
    required bool admissionFeeEnabled,
    required bool admissionFeePaid,
    required int admissionFeeAmount,
    required bool isBlocked,
  }) {
    final aDate = Dates.parse(admissionDate);
    final tDate = Dates.parse(today);

    final membershipPaid = replayMembershipPaid(ledger);
    final credit = replayCredit(ledger);

    final monthsCovered = cyclePrice > 0 ? membershipPaid ~/ cyclePrice : 0;
    final paidTill = cyclePrice > 0 ? Dates.addMonths(aDate, monthsCovered) : null;

    // Due: months elapsed past paidTill x cycle price.
    int engineDue = 0;
    int daysLeft = 0;
    int daysOverdue = 0;
    if (paidTill != null) {
      if (tDate.isAfter(paidTill)) {
        final overdueMonths = Dates.monthsBetween(paidTill, tDate);
        engineDue = overdueMonths > 0 ? overdueMonths * cyclePrice : 0;
        daysOverdue = Dates.daysBetween(tDate, paidTill).abs();
      } else {
        daysLeft = Dates.daysBetween(paidTill, tDate);
        if (daysLeft < 0) daysLeft = 0;
      }
    }

    final admDue = admissionFeeEnabled && !admissionFeePaid ? admissionFeeAmount : 0;

    MemberStatus status;
    if (isBlocked) {
      status = MemberStatus.blocked;
    } else if (paidTill != null && tDate.isAfter(paidTill)) {
      status = MemberStatus.expired;
    } else if (engineDue > 0) {
      status = MemberStatus.expired;
    } else if (admDue > 0) {
      status = MemberStatus.due;
    } else if (daysLeft <= 7) {
      status = MemberStatus.nearExpiry;
    } else {
      // Inactive: no visit for > 7 days.
      status = MemberStatus.active;
    }

    return StudentStatus(
      status: status,
      cyclePrice: cyclePrice,
      monthsCovered: monthsCovered,
      paidTill: paidTill,
      engineDue: engineDue,
      admissionFeeDue: admDue,
      credit: credit,
      daysLeft: daysLeft,
      daysOverdue: daysOverdue,
      membershipPaid: membershipPaid,
    );
  }
}
