/// Just Dance — Fee Engine v2 (pure Dart, ledger-based, realtime).
///
/// Model
/// -----
/// Every student's fee position is derived from three persisted numbers on the
/// student row plus the immutable ledger:
///   * monthsCovered — how many full monthly cycles are paid for.
///   * credit        — leftover money pool (< one cycle price, unless a course
///                     fee edit just made it larger — see AUTO_CREDIT_ADJUST).
///   * admissionFeePaidAmount — folded from ADMISSION_FEE_PAID entries.
///
/// Cycles start on the admission date and each calendar month after it
/// (calendar-safe: Jan 31 -> Feb 28). A cycle is payable from its first day,
/// so with zero payments the full first cycle is due from admission day.
///
/// Status is NEVER stored — it is recomputed on render, on resume, at midnight
/// and after every mutation.
library;

import '../core/utils.dart';
import 'models.dart';

class FeeState {
  int monthsCovered;
  double credit;
  double admissionFeePaidAmount;
  double ptPaid;
  FeeState({
    this.monthsCovered = 0,
    this.credit = 0,
    this.admissionFeePaidAmount = 0,
    this.ptPaid = 0,
  });

  double cycleBalance(double cyclePrice) =>
      (credit > 0 && credit < cyclePrice) ? cyclePrice - credit : 0;
}

class FeeStatus {
  final double cyclePrice;
  final int cyclesStarted; // cycles whose first day <= today
  final int monthsCovered;
  final double credit;
  final double feeDue; // plan/cycle dues only
  final double admissionDue; // unpaid admission fee
  final double due; // feeDue + admissionDue
  final DateTime paidTill;
  final int daysLeft; // negative => overdue days
  final bool expired; // today > paidTill
  final double advance; // prepaid future value (only when nothing is due)

  const FeeStatus({
    required this.cyclePrice,
    required this.cyclesStarted,
    required this.monthsCovered,
    required this.credit,
    required this.feeDue,
    required this.admissionDue,
    required this.due,
    required this.paidTill,
    required this.daysLeft,
    required this.expired,
    required this.advance,
  });

  bool get hasDue => due > 0.004; // ignore paisa-level float dust
}

class FeeEngine {
  /// Fold the ledger (stable order: date, id) into a [FeeState].
  /// PAYMENT entries carry a cycle-price snapshot so replay is deterministic
  /// even after course fee edits (edits are future-only).
  static FeeState replay(List<LedgerEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final s = FeeState();
    for (final e in sorted) {
      switch (e.type) {
        case kLtPayment:
          // Money + any discount given on it both buy cycle value; discounts
          // never count as money collected (Collections sums paidAmount only).
          s.credit += e.paidAmount + e.discount;
          final p = e.cyclePrice;
          if (p > 0) {
            while (s.credit >= p - 0.004) {
              s.credit -= p;
              s.monthsCovered += 1;
            }
            if (s.credit < 0.005) s.credit = 0;
          }
          break;
        case kLtAdmission:
          s.admissionFeePaidAmount += e.paidAmount;
          break;
        case kLtAutoCredit:
          // A previously-recorded auto conversion of credit into a cycle.
          s.credit -= e.cyclePrice;
          if (s.credit < 0) s.credit = 0;
          s.monthsCovered += 1;
          break;
        case kLtPtPayment:
          s.ptPaid += e.paidAmount;
          break;
        default:
          break; // PLAN_CHANGE / NOTE are informational
      }
    }
    return s;
  }

  /// Apply a fresh payment at write-time. [amount] is the cash received;
  /// [discount] is extra value given free (never counts as money collected).
  /// Allocation order: admission fee -> cycles (oldest first, then advance
  /// cycles) -> credit pool. Discount buys cycle value only.
  static PaymentSplit applyPayment({
    required FeeState state,
    required double amount,
    required double cyclePrice,
    required double admissionFeeRemaining,
    double discount = 0,
  }) {
    var left = amount;
    var toAdmission = 0.0;
    if (admissionFeeRemaining > 0 && left > 0) {
      toAdmission =
          left >= admissionFeeRemaining ? admissionFeeRemaining : left;
      state.admissionFeePaidAmount += toAdmission;
      left -= toAdmission;
    }
    state.credit += left + discount;
    if (cyclePrice > 0) {
      while (state.credit >= cyclePrice - 0.004) {
        state.credit -= cyclePrice;
        state.monthsCovered += 1;
      }
      if (state.credit < 0.005) state.credit = 0;
    }
    return PaymentSplit(toAdmission: toAdmission, toPlan: left);
  }

  /// Auto credit-consume loop: when a cycle price change leaves the credit
  /// pool large enough to cover whole cycles, convert them. Returns the number
  /// of conversions (caller writes one AUTO_CREDIT_ADJUST entry each).
  static int autoConsume(FeeState state, double cyclePrice) {
    if (cyclePrice <= 0) return 0;
    var n = 0;
    while (state.credit >= cyclePrice - 0.004) {
      state.credit -= cyclePrice;
      state.monthsCovered += 1;
      n++;
    }
    if (state.credit < 0.005) state.credit = 0;
    return n;
  }

  /// Realtime status. [cyclePrice] = sum of the student's current course fees.
  /// Uncovered cycles are billed at the CURRENT price (course edits are
  /// future-only; covered cycles stay covered regardless of price changes).
  static FeeStatus status({
    required FeeState state,
    required double cyclePrice,
    required double admissionFeeAmount,
    required bool admissionFeeEnabled,
    required DateTime admissionDate,
    required DateTime today,
  }) {
    final t = dateOnly(today);
    final cyclesStarted =
        dateOnly(admissionDate).isAfter(t) ? 0 : monthDiff(admissionDate, t) + 1;
    final uncovered =
        (cyclesStarted - state.monthsCovered).clamp(0, 1 << 31);
    var feeDue = uncovered * cyclePrice - state.credit;
    if (feeDue < 0) feeDue = 0;
    final admissionDue = admissionFeeEnabled
        ? (admissionFeeAmount - state.admissionFeePaidAmount)
            .clamp(0.0, double.infinity)
        : 0.0;
    final paidTill = addMonths(admissionDate, state.monthsCovered);
    final daysLeft = daysBetween(t, paidTill);
    final advance = feeDue <= 0
        ? (state.monthsCovered - cyclesStarted).clamp(0, 1 << 31) * cyclePrice +
            state.credit
        : 0.0;
    return FeeStatus(
      cyclePrice: cyclePrice,
      cyclesStarted: cyclesStarted,
      monthsCovered: state.monthsCovered,
      credit: state.credit,
      feeDue: feeDue,
      admissionDue: admissionDue.toDouble(),
      due: feeDue + admissionDue,
      paidTill: paidTill,
      daysLeft: daysLeft,
      expired: dateOnly(paidTill).isBefore(t),
      advance: advance.toDouble(),
    );
  }
}

class PaymentSplit {
  final double toAdmission;
  final double toPlan;
  const PaymentSplit({required this.toAdmission, required this.toPlan});
}

/// PT fees are a RECHARGE, fully separate from course/plan fees:
/// the member tops up money and every done session consumes [sessionPrice]
/// from the balance. The app reminds the member when the balance runs low.
class PtEngine {
  /// Balance left after the done sessions consumed their price.
  static double balance({
    required double paid,
    required int sessionsDone,
    required double sessionPrice,
  }) =>
      paid - sessionsDone * sessionPrice;

  /// Whole sessions the current balance can still cover.
  static int sessionsAvailable({
    required double paid,
    required int sessionsDone,
    required double sessionPrice,
  }) {
    if (sessionPrice <= 0) return 0;
    final bal = balance(
        paid: paid, sessionsDone: sessionsDone, sessionPrice: sessionPrice);
    if (bal < 0) return 0;
    return (bal / sessionPrice).floor();
  }

  /// Money needed so the balance covers [sessions] more sessions (0 if fine).
  static double rechargeNeed({
    required double paid,
    required int sessionsDone,
    required double sessionPrice,
    int sessions = 2,
  }) {
    if (sessionPrice <= 0) return 0;
    final bal = balance(
        paid: paid, sessionsDone: sessionsDone, sessionPrice: sessionPrice);
    final need = sessions * sessionPrice - bal;
    return need > 0 ? need : 0;
  }
}

// Local aliases so the engine file does not depend on the constants library
// (keeps unit tests light and the dependency direction one-way).
const kLtPayment = 'PAYMENT';
const kLtAdmission = 'ADMISSION_FEE_PAID';
const kLtAutoCredit = 'AUTO_CREDIT_ADJUST';
const kLtPtPayment = 'PT_PAYMENT';
