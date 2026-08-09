import 'package:flutter_test/flutter_test.dart';
import 'package:studio_crow/models/student.dart';
import 'package:studio_crow/services/fee_engine.dart';

void main() {
  group('Fee Engine V2 - 21 Core Logic Unit Tests', () {
    final admissionDate = DateTime(2026, 1, 1);

    Student createSampleStudent({
      int monthsCovered = 0,
      double cycleBalance = 0.0,
      double credit = 0.0,
      bool admissionFeePaid = true,
      bool admissionFeeEnabled = true,
      bool isBlocked = false,
      DateTime? lastVisitDate,
    }) {
      return Student(
        id: 1,
        jdNo: 'JD-001',
        name: 'Rahul Kumar',
        category: 'MALE',
        hobbies: ['Dancing'],
        services: ['Gym Membership'],
        mobile: '9999999999',
        admissionDate: admissionDate,
        plan: 'Monthly',
        monthsCovered: monthsCovered,
        cycleBalance: cycleBalance,
        credit: credit,
        admissionFeePaid: admissionFeePaid,
        admissionFeeEnabled: admissionFeeEnabled,
        isBlocked: isBlocked,
        lastVisitDate: lastVisitDate,
      );
    }

    // 1. Monthly paid normally
    test('1. Monthly paid normally increases monthsCovered by 1', () {
      final s = createSampleStudent();
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 1000,
        cyclePrice: 1000,
      );
      expect(result.newMonthsCovered, equals(1));
      expect(result.newCredit, equals(0.0));
    });

    // 2. Quarterly payment
    test('2. Quarterly payment increases monthsCovered by 3', () {
      final s = createSampleStudent();
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 3000,
        cyclePrice: 1000,
      );
      expect(result.newMonthsCovered, equals(3));
    });

    // 3. Partial payment
    test('3. Partial payment retains remaining balance in credit', () {
      final s = createSampleStudent();
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 500,
        cyclePrice: 1000,
      );
      expect(result.newMonthsCovered, equals(0));
      expect(result.newCredit, equals(500.0));
    });

    // 4. Admission fee unpaid
    test('4. Admission fee unpaid deducts 500 first', () {
      final s = createSampleStudent(admissionFeePaid: false, admissionFeeEnabled: true);
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 1500,
        cyclePrice: 1000,
      );
      expect(result.admissionFeePaid, isTrue);
      expect(result.newMonthsCovered, equals(1));
    });

    // 5. Admission fee paid
    test('5. Admission fee already paid allocates full amount to fee cycles', () {
      final s = createSampleStudent(admissionFeePaid: true);
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 1000,
        cyclePrice: 1000,
      );
      expect(result.newMonthsCovered, equals(1));
    });

    // 6. Overpayment
    test('6. Overpayment creates credit balance', () {
      final s = createSampleStudent();
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 1250,
        cyclePrice: 1000,
      );
      expect(result.newMonthsCovered, equals(1));
      expect(result.newCredit, equals(250.0));
    });

    // 7. Advance
    test('7. Advance payment extends monthsCovered ahead', () {
      final s = createSampleStudent(monthsCovered: 2);
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 2000,
        cyclePrice: 1000,
      );
      expect(result.newMonthsCovered, equals(4));
    });

    // 8. Credit
    test('8. Existing credit is combined with new payment', () {
      final s = createSampleStudent(credit: 400.0);
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 600.0,
        cyclePrice: 1000,
      );
      expect(result.newMonthsCovered, equals(1));
      expect(result.newCredit, equals(0.0));
    });

    // 9. Credit auto-consumption
    test('9. Credit auto-consumption clears pending cycle balance', () {
      final s = createSampleStudent(cycleBalance: 300.0, credit: 500.0);
      final result = FeeEngine.processAutoCreditAdjustment(
        student: s,
        cyclePrice: 1000,
      );
      expect(result.newCycleBalance, equals(0.0));
      expect(result.autoCreditAdjusted, equals(300.0));
      expect(result.newCredit, equals(200.0));
    });

    // 10. Zero payment validation
    test('10. Zero payment throws ArgumentError', () {
      final s = createSampleStudent();
      expect(
        () => FeeEngine.processPaymentAllocation(student: s, paidAmount: 0, cyclePrice: 1000),
        throwsArgumentError,
      );
    });

    // 11. Negative payment rejection
    test('11. Negative payment throws ArgumentError', () {
      final s = createSampleStudent();
      expect(
        () => FeeEngine.processPaymentAllocation(student: s, paidAmount: -500, cyclePrice: 1000),
        throwsArgumentError,
      );
    });

    // 12. Payment on expiry boundary
    test('12. Payment on expiry boundary extends paidTill correctly', () {
      final paidTill = FeeEngine.calculatePaidTill(DateTime(2026, 1, 15), 1);
      expect(paidTill, equals(DateTime(2026, 2, 15)));
    });

    // 13. Today == paidTill
    test('13. Today == paidTill evaluates to ACTIVE status', () {
      final s = createSampleStudent(monthsCovered: 1);
      final paidTill = FeeEngine.calculatePaidTill(s.admissionDate, 1); // 2026-02-01
      final eval = FeeEngine.evaluateStudent(s, today: paidTill);
      expect(eval.status, equals(MemberStatus.nearExpiry)); // <= 7 days left, not expired
    });

    // 14. Today > paidTill
    test('14. Today > paidTill evaluates to EXPIRED status', () {
      final s = createSampleStudent(monthsCovered: 1);
      final afterExpiry = DateTime(2026, 2, 2);
      final eval = FeeEngine.evaluateStudent(s, today: afterExpiry);
      expect(eval.status, equals(MemberStatus.expired));
    });

    // 15. Plan change
    test('15. Plan change calculates new paidTill cleanly', () {
      final paidTill1 = FeeEngine.calculatePaidTill(admissionDate, 1);
      final paidTill3 = FeeEngine.calculatePaidTill(admissionDate, 4);
      expect(paidTill1, equals(DateTime(2026, 2, 1)));
      expect(paidTill3, equals(DateTime(2026, 5, 1)));
    });

    // 16. Future price change
    test('16. Future price change allocates based on new cycle price', () {
      final s = createSampleStudent(monthsCovered: 1);
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 1200,
        cyclePrice: 1200, // New updated price
      );
      expect(result.newMonthsCovered, equals(2));
    });

    // 17. Admission fee enabled later
    test('17. Admission fee enabled later handles unpaid status safely', () {
      final s = createSampleStudent(admissionFeePaid: false, admissionFeeEnabled: true);
      final result = FeeEngine.processPaymentAllocation(
        student: s,
        paidAmount: 500,
        cyclePrice: 1000,
      );
      expect(result.admissionFeePaid, isTrue);
      expect(result.newMonthsCovered, equals(0));
    });

    // 18. Multiple overdue cycles
    test('18. Multiple overdue cycles calculated properly', () {
      final s = createSampleStudent(monthsCovered: 0);
      final eval = FeeEngine.evaluateStudent(s, today: DateTime(2026, 4, 1));
      expect(eval.status, equals(MemberStatus.expired));
      expect(eval.daysLeft, isNegative);
    });

    // 19. Leap year calculation
    test('19. Leap year handles Feb 29 safely', () {
      final feb29 = FeeEngine.calculatePaidTill(DateTime(2024, 1, 29), 1); // 2024 is leap year
      expect(feb29, equals(DateTime(2024, 2, 29)));
    });

    // 20. Month-end dates
    test('20. Month-end dates (Jan 31 + 1 mo = Feb 28) handled without overflow', () {
      final febEnd = FeeEngine.calculatePaidTill(DateTime(2026, 1, 31), 1); // 2026 non-leap year
      expect(febEnd, equals(DateTime(2026, 2, 28)));
    });

    // 21. Replay ledger consistency
    test('21. Ledger replay consistency calculates expected total paid', () {
      final s = createSampleStudent();
      var current = s;

      final res1 = FeeEngine.processPaymentAllocation(student: current, paidAmount: 1000, cyclePrice: 1000);
      current = Student.fromMap({...current.toMap(), 'monthsCovered': res1.newMonthsCovered});

      final res2 = FeeEngine.processPaymentAllocation(student: current, paidAmount: 2000, cyclePrice: 1000);
      expect(res2.newMonthsCovered, equals(3));
    });
  });
}
