import '../models/student.dart';

class FeeEngineResult {
  final MemberStatus status;
  final DateTime paidTill;
  final int daysLeft;
  final double dueAmount;
  final double creditAmount;

  const FeeEngineResult({
    required this.status,
    required this.paidTill,
    required this.daysLeft,
    required this.dueAmount,
    required this.creditAmount,
  });
}

class PaymentAllocationResult {
  final int newMonthsCovered;
  final double newCycleBalance;
  final double newCredit;
  final bool admissionFeePaid;
  final double autoCreditAdjusted;
  final String monthLabel;
  final double dueAmount;

  const PaymentAllocationResult({
    required this.newMonthsCovered,
    required this.newCycleBalance,
    required this.newCredit,
    required this.admissionFeePaid,
    required this.autoCreditAdjusted,
    required this.monthLabel,
    required this.dueAmount,
  });
}

class FeeEngine {
  /// Pure function to calculate paidTill date from admissionDate and monthsCovered
  static DateTime calculatePaidTill(DateTime admissionDate, int monthsCovered) {
    if (monthsCovered <= 0) return admissionDate;
    var year = admissionDate.year + (admissionDate.month + monthsCovered - 1) ~/ 12;
    var month = (admissionDate.month + monthsCovered - 1) % 12 + 1;
    var day = admissionDate.day;
    var lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfTargetMonth) {
      day = lastDayOfTargetMonth;
    }
    return DateTime(year, month, day);
  }

  /// Evaluates current status of a student dynamically as of [today]
  static FeeEngineResult evaluateStudent(Student student, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final paidTillDate = calculatePaidTill(
      student.admissionDate,
      student.monthsCovered,
    );

    // Days difference calculation
    final daysLeft = paidTillDate.difference(todayDate).inDays;

    // Blocked check takes display priority
    if (student.isBlocked) {
      return FeeEngineResult(
        status: MemberStatus.blocked,
        paidTill: paidTillDate,
        daysLeft: daysLeft,
        dueAmount: student.cycleBalance,
        creditAmount: student.credit,
      );
    }

    // Expiry check: today > paidTill (boundary: today == paidTill is STILL PAID)
    final isExpired = todayDate.isAfter(paidTillDate);

    // Inactive check: > 7 days since lastVisitDate (or admissionDate if never visited)
    final referenceVisit = student.lastVisitDate ?? student.admissionDate;
    final daysSinceVisit = todayDate.difference(DateTime(referenceVisit.year, referenceVisit.month, referenceVisit.day)).inDays;
    final isInactive = daysSinceVisit > 7;

    MemberStatus status;
    if (isExpired) {
      status = MemberStatus.expired;
    } else if (daysLeft <= 7 && daysLeft >= 0) {
      status = MemberStatus.nearExpiry;
    } else if (isInactive) {
      status = MemberStatus.inactive;
    } else {
      status = MemberStatus.active;
    }

    return FeeEngineResult(
      status: status,
      paidTill: paidTillDate,
      daysLeft: daysLeft,
      dueAmount: student.cycleBalance,
      creditAmount: student.credit,
    );
  }

  /// Auto credit adjustment calculation (Section 34)
  static PaymentAllocationResult processAutoCreditAdjustment({
    required Student student,
    required double cyclePrice,
  }) {
    double creditUsed = 0.0;
    double creditRemaining = student.credit;
    int monthsCovered = student.monthsCovered;
    double cycleBalance = student.cycleBalance;
    bool admissionPaid = student.admissionFeePaid;

    if (cycleBalance > 0 && creditRemaining > 0) {
      if (creditRemaining >= cycleBalance) {
        creditUsed = cycleBalance;
        creditRemaining -= cycleBalance;
        cycleBalance = 0.0;
      } else {
        creditUsed = creditRemaining;
        cycleBalance -= creditRemaining;
        creditRemaining = 0.0;
      }
    }

    while (creditRemaining >= cyclePrice) {
      creditRemaining -= cyclePrice;
      monthsCovered++;
      creditUsed += cyclePrice;
    }

    final newPaidTill = calculatePaidTill(student.admissionDate, monthsCovered);
    final monthLabel = '${newPaidTill.day}/${newPaidTill.month}/${newPaidTill.year}';

    return PaymentAllocationResult(
      newMonthsCovered: monthsCovered,
      newCycleBalance: cycleBalance,
      newCredit: creditRemaining,
      admissionFeePaid: admissionPaid,
      autoCreditAdjusted: creditUsed,
      monthLabel: monthLabel,
      dueAmount: cycleBalance,
    );
  }

  /// Processes payment allocation according to Section 33 & 34:
  /// Order: 1. Admission fee (if enabled & unpaid) -> 2. Pending cycle balance -> 3. Full cycles -> 4. Advance/Credit
  static PaymentAllocationResult processPaymentAllocation({
    required Student student,
    required double paidAmount,
    required double cyclePrice,
    DateTime? paymentDate,
  }) {
    if (paidAmount <= 0) {
      throw ArgumentError('Payment amount must be positive and non-zero');
    }
    if (cyclePrice <= 0) {
      throw ArgumentError('Cycle price must be positive');
    }

    double creditUsed = 0.0;
    double freshPaidRemaining = paidAmount;
    double creditRemaining = student.credit;

    int monthsCovered = student.monthsCovered;
    double cycleBalance = student.cycleBalance;
    bool admissionPaid = student.admissionFeePaid;

    // 1. Pay admission fee if unpaid and enabled
    if (student.admissionFeeEnabled && !admissionPaid) {
      if (freshPaidRemaining >= 500.0) {
        freshPaidRemaining -= 500.0;
        admissionPaid = true;
      } else {
        final needed = 500.0 - freshPaidRemaining;
        freshPaidRemaining = 0.0;
        if (creditRemaining >= needed) {
          creditRemaining -= needed;
          creditUsed += needed;
          admissionPaid = true;
        }
      }
    }

    // 2. Pay existing cycle balance
    if (cycleBalance > 0) {
      if (freshPaidRemaining >= cycleBalance) {
        freshPaidRemaining -= cycleBalance;
        cycleBalance = 0.0;
      } else {
        cycleBalance -= freshPaidRemaining;
        freshPaidRemaining = 0.0;

        if (cycleBalance > 0 && creditRemaining > 0) {
          if (creditRemaining >= cycleBalance) {
            creditUsed += cycleBalance;
            creditRemaining -= cycleBalance;
            cycleBalance = 0.0;
          } else {
            creditUsed += creditRemaining;
            cycleBalance -= creditRemaining;
            creditRemaining = 0.0;
          }
        }
      }
    }

    // 3. Cover full cycles with remaining funds
    double totalAvailable = freshPaidRemaining + creditRemaining;
    while (totalAvailable >= cyclePrice) {
      totalAvailable -= cyclePrice;
      monthsCovered++;
    }

    final newCredit = totalAvailable;
    final newPaidTill = calculatePaidTill(student.admissionDate, monthsCovered);
    final monthLabel = '${newPaidTill.day}/${newPaidTill.month}/${newPaidTill.year}';

    return PaymentAllocationResult(
      newMonthsCovered: monthsCovered,
      newCycleBalance: cycleBalance,
      newCredit: newCredit,
      admissionFeePaid: admissionPaid,
      autoCreditAdjusted: creditUsed,
      monthLabel: monthLabel,
      dueAmount: cycleBalance,
    );
  }
}
