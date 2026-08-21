/// Just Dance — Fee Engine v2 (pure Dart, ledger-based, realtime).
///
/// Flowchart Implementation:
/// -------------------------
/// 1. User submits fees (S).
/// 2. If admission fee is levied and not paid:
///    - Deduct admission fee from S (admissionFeeRemaining).
///    - leftOutSubmittedFee = S - admissionFeeDeducted.
/// 3. When settling advance payments:
///    - Existing advance fee is adjusted towards total course fees.
///    - leftOutSubmittedFee = leftOutSubmittedFee + existingAdvance.
/// 4. Calculate total discount:
///    - totalDiscount = manualDiscount + multipleMonthsDiscount.
/// 5. Calculate total course fees:
///    - totalCourseFees = (monthlyFees * numberOfMonths) - totalDiscount.
/// 6. Calculate amount remaining:
///    - amountRemaining = leftOutSubmittedFee - totalCourseFees.
/// 7. Evaluate amount remaining:
///    - amountRemaining > 0: Advance payment of remaining amount (adjusted in next billing cycle).
///    - amountRemaining == 0: No dues, no advance, full paid.
///    - amountRemaining < 0: Dues will be remaining negative amount.
library;

import '../core/utils.dart';
import 'models.dart';

class FeeState {
  int monthsCovered;
  double credit;
  int monthsCoveredMoney;
  double creditMoney;
  double admissionFeePaidAmount;
  double ptPaid;
  double coveredValue; // Σ snapshot price of consumed cycles
  int termMonthsTotal; // total committed term months
  double termGross; // total committed term gross
  double termDiscountTotal; // total committed plan discount
  double realizedPlanDiscount; // plan discount realized into credit pool

  FeeState({
    this.monthsCovered = 0,
    this.credit = 0,
    this.monthsCoveredMoney = 0,
    this.creditMoney = 0,
    this.admissionFeePaidAmount = 0,
    this.ptPaid = 0,
    this.coveredValue = 0,
    this.termMonthsTotal = 0,
    this.termGross = 0,
    this.termDiscountTotal = 0,
    this.realizedPlanDiscount = 0,
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
  bool get hasAdvance => advance > 0.004;
}

/// Course fee and discount breakdown from flowchart.
class PlanFeeCalc {
  final double monthlyFee;
  final int planMonths;
  final double grossFee; // monthlyFee * planMonths
  final double multipleMonthsDiscount; // multi-month course discount
  final double manualDiscount;
  final double totalDiscount; // multipleMonthsDiscount + manualDiscount
  final double totalCourseFees; // grossFee - totalDiscount

  const PlanFeeCalc({
    required this.monthlyFee,
    required this.planMonths,
    required this.grossFee,
    required this.multipleMonthsDiscount,
    required this.manualDiscount,
    required this.totalDiscount,
    required this.totalCourseFees,
  });
}

class PaymentSplit {
  final double toAdmission;
  final double toPlan;
  final double multipleMonthsDiscount;
  final double manualDiscount;
  final double totalDiscount;
  final double totalCourseFees;
  final double amountRemaining;

  const PaymentSplit({
    required this.toAdmission,
    required this.toPlan,
    this.multipleMonthsDiscount = 0,
    this.manualDiscount = 0,
    this.totalDiscount = 0,
    this.totalCourseFees = 0,
    this.amountRemaining = 0,
  });
}

class FeeEngine {
  /// Number of billing cycles elapsed/started up to [today] from [admissionDate].
  static int cyclesStarted(DateTime admissionDate, DateTime today) {
    final t = dateOnly(today);
    final a = dateOnly(admissionDate);
    return a.isAfter(t) ? 0 : monthDiff(a, t) + 1;
  }

  /// Calculates total course fees and discounts according to flowchart:
  /// - totalDiscount = manualDiscount + multipleMonthsDiscount
  /// - totalCourseFees = (monthlyFees * numberOfMonths) - totalDiscount
  static PlanFeeCalc calculatePlanFee({
    required double monthlyFee,
    required int planMonths,
    String discountType = '',
    double discountValue = 0,
    double manualDiscount = 0,
  }) {
    final months = planMonths > 0 ? planMonths : 1;
    final gross = monthlyFee * months;
    var multiMonthDisc = 0.0;
    if (discountValue > 0) {
      if (discountType == 'percent') {
        multiMonthDisc = gross * discountValue / 100;
      } else if (discountType == 'rs') {
        multiMonthDisc = discountValue;
      }
    }
    multiMonthDisc = multiMonthDisc.clamp(0.0, gross);
    final mDisc = manualDiscount.clamp(0.0, gross - multiMonthDisc);
    final totDisc = (multiMonthDisc + mDisc).clamp(0.0, gross);
    final totalCourseFees = (gross - totDisc).clamp(0.0, gross);

    return PlanFeeCalc(
      monthlyFee: monthlyFee,
      planMonths: months,
      grossFee: gross,
      multipleMonthsDiscount: multiMonthDisc,
      manualDiscount: mDisc,
      totalDiscount: totDisc,
      totalCourseFees: totalCourseFees,
    );
  }

  static void _consumeCycle(FeeState state, double cyclePrice) {
    state.credit -= cyclePrice;
    state.monthsCovered += 1;
    state.coveredValue += cyclePrice;
    if (state.creditMoney > 0) {
      final moneyUsed = state.creditMoney >= cyclePrice ? cyclePrice : state.creditMoney;
      state.creditMoney -= moneyUsed;
      if (moneyUsed >= cyclePrice - 0.004) {
        state.monthsCoveredMoney += 1;
      }
    }
    if (state.creditMoney < 0.005) state.creditMoney = 0;
    if (state.credit < 0.005) {
      state.credit = 0;
      state.creditMoney = 0;
    }
  }

  /// Fold the ledger (stable order: date, id) into a [FeeState].
  /// PAYMENT and PLAN_TERM entries carry cycle-price and discount snapshots
  /// so replay is fully deterministic.
  static FeeState replay(List<LedgerEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final s = FeeState();
    for (final e in sorted) {
      switch (e.type) {
        case kLtPlanTerm:
          s.termMonthsTotal += e.termMonths;
          s.termGross += e.termMonths * e.cyclePrice;
          s.termDiscountTotal += e.discount;
          break;
        case kLtPayment:
          // Money + any discount given on it both buy cycle value; discounts
          // never count as money collected (Collections sums paidAmount only).
          s.realizedPlanDiscount += e.planDiscount;
          s.credit += e.paidAmount + e.discount;
          s.creditMoney += e.paidAmount;
          final p = e.cyclePrice;
          if (p > 0) {
            while (s.credit >= p - 0.004) {
              _consumeCycle(s, p);
            }
            if (s.credit < 0.005) s.credit = 0;
            if (s.creditMoney < 0.005) s.creditMoney = 0;
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
          s.coveredValue += e.cyclePrice;
          if (s.creditMoney >= e.cyclePrice - 0.004) {
            s.creditMoney -= e.cyclePrice;
            s.monthsCoveredMoney += 1;
          }
          if (s.creditMoney < 0) s.creditMoney = 0;
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

  /// Apply a payment according to the flowchart:
  /// 1. If admission fee is levied and unpaid -> deduct admission fee.
  /// 2. If settling advance payments -> advance fees are adjusted.
  /// 3. Calculate totalCourseFees = monthlyFees * planMonths - totalDiscount.
  /// 4. amountRemaining = leftOutSubmittedFee - totalCourseFees.
  /// 5. amountRemaining > 0 -> advance adjusted into credit pool for future cycles.
  /// 6. amountRemaining == 0 -> exact paid, 0 due.
  /// 7. amountRemaining < 0 -> partial paid, remaining is due.
  static PaymentSplit applyPayment({
    required FeeState state,
    required double amount,
    required double cyclePrice,
    required double admissionFeeRemaining,
    bool isAdmissionFeeLevied = false,
    bool isAdmissionFeePaid = true,
    int planMonths = 1,
    String planDiscountType = '',
    double planDiscountValue = 0,
    double manualDiscount = 0,
    double discount = 0, // legacy parameter support
  }) {
    var left = amount;
    var toAdmission = 0.0;

    // Step 1: Admission fee check & deduction
    if (isAdmissionFeeLevied && !isAdmissionFeePaid && admissionFeeRemaining > 0 && left > 0) {
      toAdmission = left >= admissionFeeRemaining ? admissionFeeRemaining : left;
      state.admissionFeePaidAmount += toAdmission;
      left -= toAdmission;
    }

    // Step 2 & 3: Total discount & total course fees
    final effectiveManual = manualDiscount > 0 ? manualDiscount : discount;
    final calc = calculatePlanFee(
      monthlyFee: cyclePrice,
      planMonths: planMonths,
      discountType: planDiscountType,
      discountValue: planDiscountValue,
      manualDiscount: effectiveManual,
    );

    // Plan discount capping:
    // If a term is active, realize plan discount only up to the term's unrealized remainder.
    final double planDiscountToRealize;
    if (state.termMonthsTotal > 0) {
      final unrealized = (state.termDiscountTotal - state.realizedPlanDiscount).clamp(0.0, double.infinity);
      planDiscountToRealize = calc.multipleMonthsDiscount.clamp(0.0, unrealized);
      state.realizedPlanDiscount += planDiscountToRealize;
    } else {
      planDiscountToRealize = calc.multipleMonthsDiscount;
    }
    final totalDiscountToCredit = planDiscountToRealize + calc.manualDiscount;

    // Step 4: Add left-out submitted fee + total discount to credit pool
    final available = left + totalDiscountToCredit;
    state.credit += available;
    state.creditMoney += left;

    // Step 5: Convert credit pool to covered cycles
    if (cyclePrice > 0) {
      while (state.credit >= cyclePrice - 0.004) {
        _consumeCycle(state, cyclePrice);
      }
      if (state.credit < 0.005) state.credit = 0;
      if (state.creditMoney < 0.005) state.creditMoney = 0;
    }

    final amountRemaining = left - calc.totalCourseFees;

    return PaymentSplit(
      toAdmission: toAdmission,
      toPlan: left,
      multipleMonthsDiscount: planDiscountToRealize,
      manualDiscount: calc.manualDiscount,
      totalDiscount: totalDiscountToCredit,
      totalCourseFees: calc.totalCourseFees,
      amountRemaining: amountRemaining,
    );
  }

  /// Auto credit-consume loop: when a cycle price change leaves the credit
  /// pool large enough to cover whole cycles, convert them. Returns the number
  /// of conversions (caller writes one AUTO_CREDIT_ADJUST entry each).
  static int autoConsume(FeeState state, double cyclePrice) {
    if (cyclePrice <= 0) return 0;
    var n = 0;
    while (state.credit >= cyclePrice - 0.004) {
      _consumeCycle(state, cyclePrice);
      n++;
    }
    if (state.credit < 0.005) state.credit = 0;
    if (state.creditMoney < 0.005) state.creditMoney = 0;
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
    final cyclesStartedCount = cyclesStarted(admissionDate, t);

    final double feeDue;
    if (state.termMonthsTotal > 0) {
      final earmark = (state.termDiscountTotal - state.realizedPlanDiscount).clamp(0.0, double.infinity);
      final postTermCycles = (cyclesStartedCount - state.termMonthsTotal).clamp(0, 1 << 31);
      final obligation = state.termGross - earmark + postTermCycles * cyclePrice;
      final rawFeeDue = obligation - state.coveredValue - state.credit;
      feeDue = rawFeeDue > 0 ? rawFeeDue : 0.0;
    } else {
      final uncovered = (cyclesStartedCount - state.monthsCovered).clamp(0, 1 << 31);
      final rawFeeDue = uncovered * cyclePrice - state.credit;
      feeDue = rawFeeDue > 0 ? rawFeeDue : 0.0;
    }

    final admissionDue = admissionFeeEnabled
        ? (admissionFeeAmount - state.admissionFeePaidAmount)
            .clamp(0.0, double.infinity)
        : 0.0;
    final paidTill = addMonths(admissionDate, state.monthsCovered);
    final daysLeft = daysBetween(t, paidTill);
    final advance = feeDue <= 0 ? state.creditMoney : 0.0;
    return FeeStatus(
      cyclePrice: cyclePrice,
      cyclesStarted: cyclesStartedCount,
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
const kLtPlanTerm = 'PLAN_TERM';


