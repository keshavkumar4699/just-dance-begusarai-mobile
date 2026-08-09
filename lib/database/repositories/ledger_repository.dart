import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/ledger_entry.dart';
import '../../models/student.dart';
import '../../services/fee_engine.dart';

class LedgerRepository {
  final DatabaseHelper _dbHelper;

  LedgerRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Inserts a ledger entry into the database
  Future<int> insertLedgerEntry(LedgerEntry entry, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.insert('ledger', entry.toMap());
    } else {
      final db = await _dbHelper.database;
      return await db.insert('ledger', entry.toMap());
    }
  }

  /// Records a fee payment transactionally and updates student balances
  Future<void> recordPayment({
    required Student student,
    required double paidAmount,
    required double cyclePrice,
    required String paymentMode,
    String? note,
    DateTime? paymentDate,
  }) async {
    if (paidAmount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero');
    }

    final db = await _dbHelper.database;
    final now = paymentDate ?? DateTime.now();

    await db.transaction((txn) async {
      final calculation = FeeEngine.processPaymentAllocation(
        student: student,
        paidAmount: paidAmount,
        cyclePrice: cyclePrice,
        paymentDate: now,
      );

      // Create primary payment ledger entry
      final ledgerEntry = LedgerEntry(
        studentId: student.id!,
        date: now,
        type: 'PAYMENT',
        monthLabel: calculation.monthLabel,
        dueAmount: calculation.dueAmount,
        paidAmount: paidAmount,
        balanceOrCredit: calculation.newCredit > 0 ? calculation.newCredit : calculation.newCycleBalance,
        mode: paymentMode,
        note: note ?? 'Fee payment',
      );
      await txn.insert('ledger', ledgerEntry.toMap());

      // If auto-credit adjustment occurred during payment processing
      if (calculation.autoCreditAdjusted > 0) {
        final autoCreditEntry = LedgerEntry(
          studentId: student.id!,
          date: now,
          type: 'AUTO_CREDIT_ADJUST',
          monthLabel: 'Auto Credit',
          dueAmount: 0.0,
          paidAmount: calculation.autoCreditAdjusted,
          balanceOrCredit: calculation.newCredit,
          mode: 'Credit',
          note: 'Advance credit auto-applied to fee cycle',
        );
        await txn.insert('ledger', autoCreditEntry.toMap());
      }

      // Update student balances inside transaction
      await txn.update(
        'students',
        {
          'monthsCovered': calculation.newMonthsCovered,
          'cycleBalance': calculation.newCycleBalance,
          'credit': calculation.newCredit,
          'admissionFeePaid': calculation.admissionFeePaid ? 1 : 0,
          'updatedAt': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [student.id],
      );
    });
  }

  /// Records Personal Training payment transactionally
  Future<void> recordPTPayment({
    required Student student,
    required double paidAmount,
    required String paymentMode,
    String? note,
  }) async {
    if (paidAmount <= 0) return;

    final db = await _dbHelper.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final updatedPTPaid = student.ptPaid + paidAmount;

      final ledgerEntry = LedgerEntry(
        studentId: student.id!,
        date: now,
        type: 'PT_PAYMENT',
        monthLabel: 'PT Fee',
        dueAmount: (student.ptSessions * student.ptSessionPrice) - updatedPTPaid,
        paidAmount: paidAmount,
        balanceOrCredit: 0.0,
        mode: paymentMode,
        note: note ?? 'Personal Training Payment',
      );
      await txn.insert('ledger', ledgerEntry.toMap());

      await txn.update(
        'students',
        {
          'ptPaid': updatedPTPaid,
          'updatedAt': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [student.id],
      );
    });
  }

  /// Fetches ledger history for a student sorted by date
  Future<List<LedgerEntry>> getLedgerForStudent(int studentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ledger',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => LedgerEntry.fromMap(m)).toList();
  }

  /// Fetches all ledger entries for financial reporting
  Future<List<LedgerEntry>> getAllLedgerEntries({int limit = 100}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ledger',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return maps.map((m) => LedgerEntry.fromMap(m)).toList();
  }
}
