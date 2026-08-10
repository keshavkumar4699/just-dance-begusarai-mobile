import 'package:flutter_test/flutter_test.dart';

import 'package:studio_crow/constants.dart';
import 'package:studio_crow/models/models.dart';
import 'package:studio_crow/services/fee_engine.dart';
import 'package:studio_crow/utils/date_utils.dart';

LedgerEntry pay(int amount, {int due = 0, int bal = 0, String type = LedgerType.payment}) =>
    LedgerEntry(
      studentId: 1,
      date: Dates.todayStr(),
      type: type,
      dueAmount: due,
      paidAmount: amount,
      balanceOrCredit: bal,
      mode: 'Cash',
      note: '',
    );

void main() {
  group('Dates.addMonths - calendar safe', () {
    test('Jan 31 + 1 month = Feb 28', () {
      final r = Dates.addMonths(DateTime(2026, 1, 31), 1);
      expect(r.year, 2026);
      expect(r.month, 2);
      expect(r.day, 28);
    });

    test('Jan 31 + 1 month (leap year) = Feb 29', () {
      final r = Dates.addMonths(DateTime(2024, 1, 31), 1);
      expect(r.day, 29);
    });

    test('Dec 15 + 2 months = Feb 15 next year', () {
      final r = Dates.addMonths(DateTime(2026, 12, 15), 2);
      expect(r.year, 2027);
      expect(r.month, 2);
      expect(r.day, 15);
    });

    test('monthsBetween Jul 15 -> Aug 16 = 1', () {
      expect(Dates.monthsBetween(DateTime(2026, 7, 15), DateTime(2026, 8, 16)), 1);
    });
  });

  group('FeeEngine.applyDiscount', () {
    test('10% of 3000 = 300', () {
      expect(FeeEngine.applyDiscount(3000, '%', 10), 300);
    });

    test('₹500 of 3000 = 500', () {
      expect(FeeEngine.applyDiscount(3000, '₹', 500), 500);
    });

    test('percent capped at 100', () {
      expect(FeeEngine.applyDiscount(3000, '%', 150), 3000);
    });

    test('₹ never exceeds base', () {
      expect(FeeEngine.applyDiscount(1000, '₹', 5000), 1000);
    });

    test('negative values = no discount', () {
      expect(FeeEngine.applyDiscount(1000, '%', -5), 0);
    });
  });

  group('Fee engine - core', () {
    const admission = '2026-07-15';

    StudentStatus compute(List<LedgerEntry> ledger, {String today = '2026-07-15'}) =>
        FeeEngine.computeStatus(
          cyclePrice: 1000,
          admissionDate: admission,
          today: today,
          ledger: ledger,
          admissionFeeEnabled: false,
          admissionFeePaid: false,
          admissionFeeAmount: 0,
          isBlocked: false,
        );

    test('pay 1000 on monthly -> paidTill +1 month, due 0', () {
      final st = compute([pay(1000)], today: '2026-07-15');
      expect(st.monthsCovered, 1);
      expect(Dates.fmt(st.paidTill!), '2026-08-15');
      expect(st.engineDue, 0);
      expect(st.status, MemberStatus.active);
    });

    test('pay 3000 on quarterly 3000 -> +3 months', () {
      final st = compute([pay(3000)], today: '2026-07-15');
      expect(st.monthsCovered, 3);
      expect(Dates.fmt(st.paidTill!), '2026-10-15');
    });

    test('pay 1200 -> 200 advance credit', () {
      // In the app the ledger stores balanceOrCredit = paid - due (200).
      final st = compute([pay(1200, bal: 200)], today: '2026-07-15');
      expect(st.monthsCovered, 1);
      expect(st.credit, 200);
    });

    test('overpay + later due -> credit auto-consumes a cycle', () {
      // Paid 3000 on Jul 15 (3 months). Today Oct 16 -> 1 month overdue (1000).
      final ledger = [
        pay(3000),
        // AUTO_CREDIT_ADJUST consumes 1000 of the credit.
        LedgerEntry(
          studentId: 1,
          date: '2026-10-16',
          type: LedgerType.autoCreditAdjust,
          dueAmount: 1000,
          paidAmount: 1000,
          balanceOrCredit: 0,
          mode: 'Advance',
          note: 'Auto credit adjustment',
        ),
      ];
      final st = compute(ledger, today: '2026-10-16');
      expect(st.monthsCovered, 4);
      expect(Dates.fmt(st.paidTill!), '2026-11-15');
      expect(st.engineDue, 0);
      expect(st.credit, 0);
    });

    test('zero payments -> due from admission', () {
      final st = compute(const [], today: '2026-08-16');
      expect(st.monthsCovered, 0);
      expect(st.engineDue, 1000);
      expect(st.status, MemberStatus.expired);
    });

    test('boundary today == paidTill -> PAID (near expiry, not expired)', () {
      final st = compute([pay(1000)], today: '2026-08-15');
      expect(st.engineDue, 0);
      expect(st.status, MemberStatus.nearExpiry,
          reason: 'today == paidTill means fees are paid, plan ends today');
      expect(Dates.fmt(st.paidTill!), '2026-08-15');
    });

    test('daysLeft <= 7 -> near expiry', () {
      final st = compute([pay(1000)], today: '2026-08-10');
      expect(st.daysLeft, 5);
      expect(st.status, MemberStatus.nearExpiry);
    });

    test('inactive > 7 days is inactive only via statusFor logic (chip)', () {
      // The engine itself doesn't know visits; AppState applies it. Here we
      // just verify paidTill math is untouched.
      final st = compute([pay(1000)], today: '2026-08-20');
      expect(st.daysOverdue, 5);
      expect(st.status, MemberStatus.expired);
    });

    test('blocked -> blocked status', () {
      final st = FeeEngine.computeStatus(
        cyclePrice: 1000,
        admissionDate: admission,
        today: '2026-07-15',
        ledger: const [],
        admissionFeeEnabled: false,
        admissionFeePaid: false,
        admissionFeeAmount: 0,
        isBlocked: true,
      );
      expect(st.status, MemberStatus.blocked);
    });

    test('admission fee toggle ON later -> due from that day', () {
      final st = FeeEngine.computeStatus(
        cyclePrice: 0,
        admissionDate: admission,
        today: '2026-07-20',
        ledger: const [],
        admissionFeeEnabled: true,
        admissionFeePaid: false,
        admissionFeeAmount: 500,
        isBlocked: false,
      );
      expect(st.admissionFeeDue, 500);
      expect(st.status, MemberStatus.due);
    });
  });

  group('Ledger replay', () {
    test('replayCredit sums positive balances, subtracts adjustments', () {
      final ledger = [
        pay(1200, bal: 200),
        LedgerEntry(
          studentId: 1,
          date: '2026-08-15',
          type: LedgerType.autoCreditAdjust,
          dueAmount: 1000,
          paidAmount: 1000,
          balanceOrCredit: 0,
          mode: 'Advance',
          note: '',
        ),
      ];
      expect(FeeEngine.replayCredit(ledger), 0);
    });

    test('PT payments replay independently', () {
      final ledger = [pay(500, type: LedgerType.ptPayment)];
      expect(FeeEngine.replayPtPaid(ledger), 500);
      expect(FeeEngine.replayMembershipPaid(ledger), 0);
    });
  });
}
