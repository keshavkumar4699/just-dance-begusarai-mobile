import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/ledger_entry.dart';
import '../constants.dart';

class FeeEngine {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  static String getCurrentMonthYear() {
    final now = DateTime.now();
    return DateFormat('MMM yyyy').format(now);
  }

  static Map<String, dynamic> calculateDashboardStats({
    required List<Student> students,
    required List<LedgerEntry> ledgerEntries,
  }) {
    double totalCollectedMonth = 0.0;
    double totalPendingMonth = 0.0;
    int activeCount = 0;
    int pendingCount = 0;
    int overdueCount = 0;

    final currentMonthYear = getCurrentMonthYear();

    for (var student in students) {
      if (student.status == 'Active') activeCount++;
      if (student.status == 'Pending') pendingCount++;
      if (student.status == 'Overdue') overdueCount++;
    }

    for (var entry in ledgerEntries) {
      if (entry.monthYear == currentMonthYear) {
        totalCollectedMonth += entry.amountPaid;
        totalPendingMonth += entry.balanceRemaining;
      }
    }

    return {
      'totalStudents': students.length,
      'activeStudents': activeCount,
      'pendingStudents': pendingCount,
      'overdueStudents': overdueCount,
      'totalCollectedMonth': totalCollectedMonth,
      'totalPendingMonth': totalPendingMonth,
    };
  }

  static String evaluateStudentStatus(List<LedgerEntry> studentLedger) {
    if (studentLedger.isEmpty) return 'Active';
    
    bool hasOverdue = studentLedger.any((entry) => entry.status == 'Overdue');
    if (hasOverdue) return 'Overdue';

    bool hasPending = studentLedger.any((entry) => entry.status == 'Pending');
    if (hasPending) return 'Pending';

    return 'Active';
  }
}
