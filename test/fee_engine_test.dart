import 'package:flutter_test/flutter_test.dart';
import 'package:studio_crow/data/fee_engine.dart';
import 'package:studio_crow/data/models.dart';
import 'package:studio_crow/services/invoice_pdf.dart';

void main() {
  group('FeeEngine Flowchart Calculations', () {
    test('calculatePlanFee: total discount = manual discount + multiple months discount', () {
      final calc = FeeEngine.calculatePlanFee(
        monthlyFee: 1000,
        planMonths: 3,
        discountType: 'percent',
        discountValue: 10,
        manualDiscount: 100,
      );

      expect(calc.grossFee, 3000);
      expect(calc.multipleMonthsDiscount, 300);
      expect(calc.manualDiscount, 100);
      expect(calc.totalDiscount, 400);
      expect(calc.totalCourseFees, 2600);
    });

    test('calculatePlanFee: fixed rupee multi-month discount', () {
      final calc = FeeEngine.calculatePlanFee(
        monthlyFee: 1500,
        planMonths: 2,
        discountType: 'rs',
        discountValue: 200,
        manualDiscount: 50,
      );

      expect(calc.grossFee, 3000);
      expect(calc.multipleMonthsDiscount, 200);
      expect(calc.manualDiscount, 50);
      expect(calc.totalDiscount, 250);
      expect(calc.totalCourseFees, 2750);
    });

    test('Flowchart Step 1 & 2: Admission fee levied and unpaid is deducted first', () {
      final state = FeeState();
      final split = FeeEngine.applyPayment(
        state: state,
        amount: 3500,
        cyclePrice: 1000,
        admissionFeeRemaining: 500,
        isAdmissionFeeLevied: true,
        isAdmissionFeePaid: false,
        planMonths: 3,
      );

      expect(split.toAdmission, 500);
      expect(split.toPlan, 3000);
      expect(state.admissionFeePaidAmount, 500);
      expect(state.monthsCovered, 3);
      expect(state.credit, 0);
      expect(split.amountRemaining, 0);
    });

    test('Flowchart Step 3 & 4: Advance payment settlement', () {
      final state = FeeState(credit: 1000, creditMoney: 1000);
      final split = FeeEngine.applyPayment(
        state: state,
        amount: 2000,
        cyclePrice: 1000,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: true,
        isAdmissionFeePaid: true,
        planMonths: 3,
      );

      expect(split.toAdmission, 0);
      expect(split.toPlan, 2000);
      expect(state.monthsCovered, 3);
      expect(state.credit, 0);
    });

    test('pay ₹2500 + ₹500 discount on 6-month plan -> monthsCovered 6, advance ₹0 (no extra unconsumed money)', () {
      final state = FeeState();
      final admissionDate = DateTime(2026, 1, 1);
      final split = FeeEngine.applyPayment(
        state: state,
        amount: 2500,
        cyclePrice: 500,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: false,
        isAdmissionFeePaid: true,
        planMonths: 6,
        manualDiscount: 500,
      );

      expect(split.totalDiscount, 500);
      expect(state.monthsCovered, 6);
      expect(state.monthsCoveredMoney, 5);
      expect(state.credit, 0);
      expect(state.creditMoney, 0);

      // Membership is valid till July 1; advance credit is ₹0 (all money allocated to cycles)
      final statusOn = FeeEngine.status(
        state: state,
        cyclePrice: 500,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: admissionDate,
      );
      expect(statusOn.monthsCovered, 6);
      expect(statusOn.paidTill, DateTime(2026, 7, 1));
      expect(statusOn.due, 0);
      expect(statusOn.advance, 0);
    });

    test('plain advance: extra unconsumed money creates advance credit', () {
      final state = FeeState();
      final admissionDate = DateTime(2026, 1, 1);
      FeeEngine.applyPayment(
        state: state,
        amount: 2500,
        cyclePrice: 1000,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: false,
        isAdmissionFeePaid: true,
        planMonths: 2,
      );

      expect(state.monthsCovered, 2);
      expect(state.monthsCoveredMoney, 2);
      expect(state.credit, 500);
      expect(state.creditMoney, 500);

      // ₹2000 covered 2 months; remaining ₹500 is unconsumed wallet credit
      final statusOn = FeeEngine.status(
        state: state,
        cyclePrice: 1000,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: admissionDate,
      );
      expect(statusOn.monthsCovered, 2);
      expect(statusOn.advance, 500);
      expect(statusOn.due, 0);
    });

    test('replay with AUTO_CREDIT_ADJUST', () {
      final entries = [
        LedgerEntry(
          id: 1,
          studentId: 1,
          date: DateTime(2026, 1, 1),
          type: kLtPayment,
          paidAmount: 2000,
          discount: 500,
          cyclePrice: 500,
        ),
        LedgerEntry(
          id: 2,
          studentId: 1,
          date: DateTime(2026, 2, 1),
          type: kLtAutoCredit,
          cyclePrice: 500,
        ),
      ];

      final state = FeeEngine.replay(entries);

      // Payment gave 2500 credit (5 cycles covered), then auto credit adds 1 cycle = 6
      expect(state.monthsCovered, 6);
      expect(state.monthsCoveredMoney, 4);
      expect(state.creditMoney, 0);
    });

    test('back-dated admission: 3 elapsed cycles, paying partial vs full', () {
      final admissionDate = DateTime(2026, 5, 1);
      final today = DateTime(2026, 7, 15); // May, June, July = 3 cycles started
      expect(FeeEngine.cyclesStarted(admissionDate, today), 3);

      // Case 1: 0 paid at admission -> 3 months due (₹3000)
      final state0 = FeeState();
      final status0 = FeeEngine.status(
        state: state0,
        cyclePrice: 1000,
        admissionFeeAmount: 500,
        admissionFeeEnabled: true,
        admissionDate: admissionDate,
        today: today,
      );
      expect(status0.feeDue, 3000);
      expect(status0.admissionDue, 500);
      expect(status0.due, 3500);
      expect(status0.expired, true);
      expect(status0.paidTill, admissionDate);

      // Case 2: Pay 1 month fee (₹1000)
      final state1 = FeeState();
      FeeEngine.applyPayment(
        state: state1,
        amount: 1000,
        cyclePrice: 1000,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: false,
        isAdmissionFeePaid: true,
        planMonths: 1,
      );
      expect(state1.monthsCovered, 1);
      final status1 = FeeEngine.status(
        state: state1,
        cyclePrice: 1000,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: today,
      );
      // Covered May 1 -> Jun 1; still 2 months due (June & July)
      expect(status1.feeDue, 2000);
      expect(status1.paidTill, DateTime(2026, 6, 1));
      expect(status1.expired, true);

      // Case 3: Pay all 3 months (₹3000)
      final state3 = FeeState();
      FeeEngine.applyPayment(
        state: state3,
        amount: 3000,
        cyclePrice: 1000,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: false,
        isAdmissionFeePaid: true,
        planMonths: 3,
      );
      expect(state3.monthsCovered, 3);
      final status3 = FeeEngine.status(
        state: state3,
        cyclePrice: 1000,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: today,
      );
      // Covered May, June, July -> paid till Aug 1!
      expect(status3.feeDue, 0);
      expect(status3.due, 0);
      expect(status3.paidTill, DateTime(2026, 8, 1));
      expect(status3.expired, false);
      expect(status3.advance, 0);

      // Case 4: Pay 4 months (₹4000) -> 3 months cover elapsed, 1 month advance
      final state4 = FeeState();
      FeeEngine.applyPayment(
        state: state4,
        amount: 4000,
        cyclePrice: 1000,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: false,
        isAdmissionFeePaid: true,
        planMonths: 4,
      );
      expect(state4.monthsCovered, 4);
      final status4 = FeeEngine.status(
        state: state4,
        cyclePrice: 1000,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: today,
      );
      expect(status4.feeDue, 0);
      expect(status4.paidTill, DateTime(2026, 9, 1));
      expect(status4.expired, false);
      expect(status4.advance, 0);
    });

    test('Plan Commitment: 12-month plan (₹1000/mo, 10% disc = ₹1200) with ₹0 paid -> ₹10,800 due', () {
      final admissionDate = DateTime(2026, 1, 1);
      final entries = [
        LedgerEntry(
          id: 1,
          studentId: 1,
          date: admissionDate,
          type: kLtPlanTerm,
          cyclePrice: 1000,
          termMonths: 12,
          discount: 1200,
        ),
      ];

      final state = FeeEngine.replay(entries);
      expect(state.termMonthsTotal, 12);
      expect(state.termGross, 12000);
      expect(state.termDiscountTotal, 1200);
      expect(state.realizedPlanDiscount, 0);

      final status = FeeEngine.status(
        state: state,
        cyclePrice: 1000,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: admissionDate,
      );

      expect(status.feeDue, 10800);
      expect(status.due, 10800);
      expect(status.paidTill, admissionDate);
    });

    test('Plan Commitment: Partial payment ₹5000 -> ₹5800 due; Second payment ₹5800 -> ₹0 due (no double discount)', () {
      final admissionDate = DateTime(2026, 1, 1);
      final termEntry = LedgerEntry(
        id: 1,
        studentId: 1,
        date: admissionDate,
        type: kLtPlanTerm,
        cyclePrice: 1000,
        termMonths: 12,
        discount: 1200,
      );

      // Payment 1: ₹5,000 paid
      final state1 = FeeEngine.replay([termEntry]);
      final split1 = FeeEngine.applyPayment(
        state: state1,
        amount: 5000,
        cyclePrice: 1000,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: false,
        isAdmissionFeePaid: true,
        planMonths: 12,
        planDiscountType: 'percent',
        planDiscountValue: 10,
      );

      expect(split1.multipleMonthsDiscount, 1200);
      expect(split1.totalDiscount, 1200);
      expect(state1.monthsCovered, 6); // (5000 + 1200) / 1000 = 6 cycles + 200 credit
      expect(state1.credit, 200);
      expect(state1.coveredValue, 6000);
      expect(state1.realizedPlanDiscount, 1200);

      final status1 = FeeEngine.status(
        state: state1,
        cyclePrice: 1000,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: admissionDate,
      );
      expect(status1.feeDue, 5800);

      // Replay check with payment 1 entry
      final payEntry1 = LedgerEntry(
        id: 2,
        studentId: 1,
        date: admissionDate,
        type: kLtPayment,
        paidAmount: 5000,
        discount: 1200,
        planDiscount: 1200,
        cyclePrice: 1000,
      );
      final replayedState1 = FeeEngine.replay([termEntry, payEntry1]);
      expect(replayedState1.monthsCovered, 6);
      expect(replayedState1.credit, 200);
      expect(replayedState1.realizedPlanDiscount, 1200);

      // Payment 2: ₹5,800 paid
      final split2 = FeeEngine.applyPayment(
        state: replayedState1,
        amount: 5800,
        cyclePrice: 1000,
        admissionFeeRemaining: 0,
        isAdmissionFeeLevied: false,
        isAdmissionFeePaid: true,
        planMonths: 12,
        planDiscountType: 'percent',
        planDiscountValue: 10,
      );

      // Discount was already realized in payment 1 -> capped at 0 in payment 2!
      expect(split2.multipleMonthsDiscount, 0);
      expect(split2.totalDiscount, 0);
      // Credit: 200 + 5800 = 6000 -> 6 more cycles covered = 12 total
      expect(replayedState1.monthsCovered, 12);
      expect(replayedState1.credit, 0);
      expect(replayedState1.coveredValue, 12000);

      final status2 = FeeEngine.status(
        state: replayedState1,
        cyclePrice: 1000,
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: admissionDate,
      );
      expect(status2.feeDue, 0);
      expect(status2.due, 0);
      expect(status2.paidTill, DateTime(2027, 1, 1));
      expect(status2.advance, 0);
    });

    test('Plan Commitment: 2 cycles post-term billed at current price', () {
      final admissionDate = DateTime(2026, 1, 1);
      final entries = [
        LedgerEntry(
          id: 1,
          studentId: 1,
          date: admissionDate,
          type: kLtPlanTerm,
          cyclePrice: 1000,
          termMonths: 12,
          discount: 1200,
        ),
        LedgerEntry(
          id: 2,
          studentId: 1,
          date: admissionDate,
          type: kLtPayment,
          paidAmount: 10800,
          discount: 1200,
          planDiscount: 1200,
          cyclePrice: 1000,
        ),
      ];

      final state = FeeEngine.replay(entries);
      expect(state.monthsCovered, 12);

      // Today is 14 months after admission (Month 14 active, 2 cycles past 12-mo term)
      final todayMonth14 = DateTime(2027, 2, 15);
      final status = FeeEngine.status(
        state: state,
        cyclePrice: 1200, // Price increased to 1200
        admissionFeeAmount: 0,
        admissionFeeEnabled: false,
        admissionDate: admissionDate,
        today: todayMonth14,
      );

      // 2 elapsed cycles post-term * 1200 current price = 2400 due
      expect(status.feeDue, 2400);
    });

    test('Back-date with pre-paid admission fee -> not deducted from course payment', () {
      final admissionDate = DateTime(2026, 1, 1);
      final entries = [
        LedgerEntry(
          id: 1,
          studentId: 1,
          date: admissionDate,
          type: kLtAdmission,
          paidAmount: 500,
        ),
        LedgerEntry(
          id: 2,
          studentId: 1,
          date: admissionDate,
          type: kLtPlanTerm,
          cyclePrice: 1000,
          termMonths: 3,
          discount: 0,
        ),
      ];

      final state = FeeEngine.replay(entries);
      expect(state.admissionFeePaidAmount, 500);

      final split = FeeEngine.applyPayment(
        state: state,
        amount: 3000,
        cyclePrice: 1000,
        admissionFeeRemaining: 0, // Admission already paid
        isAdmissionFeeLevied: true,
        isAdmissionFeePaid: true,
        planMonths: 3,
      );

      expect(split.toAdmission, 0);
      expect(split.toPlan, 3000);
      expect(state.monthsCovered, 3);
      expect(state.credit, 0);
    });
  });

  group('Invoice Math Tests', () {
    test('InvoiceMath total calculation', () {
      final total = InvoiceMath.total(
        gross: 3000,
        discount: 300,
      );

      expect(total, 2700);
    });

    test('InvoicePdf.rs formatting', () {
      expect(InvoicePdf.rs(1500), 'Rs. 1,500');
      expect(InvoicePdf.rs(100000), 'Rs. 1,00,000');
      expect(InvoicePdf.rs(0), 'Rs. 0');
    });
  });
}
