import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class SeedData {
  static Future<void> insertDemoData(Database db) async {
    // 1. Insert Demo Security PIN
    await db.insert('settings', {'key': 'user_security_pin', 'value': '2026'});
    await db.insert('settings', {'key': 'studio_name', 'value': 'Just Dance Academy'});
    await db.insert('settings', {'key': 'studio_location', 'value': 'Begusarai'});

    // 2. Insert Demo Students
    final students = [
      {
        'name': 'Aarav Sharma',
        'phone': '9876543210',
        'parentPhone': '9876543299',
        'danceStyles': jsonEncode(['Hip Hop', 'Contemporary']),
        'batchTiming': '5:00 PM - 6:00 PM (Evening)',
        'joiningDate': '2026-01-10',
        'monthlyFee': 1500.0,
        'dueDay': 5,
        'status': 'Active',
      },
      {
        'name': 'Ananya Verma',
        'phone': '9123456789',
        'parentPhone': '9123456700',
        'danceStyles': jsonEncode(['Kathak', 'Classical']),
        'batchTiming': '6:00 AM - 7:00 AM (Morning)',
        'joiningDate': '2026-02-01',
        'monthlyFee': 1800.0,
        'dueDay': 5,
        'status': 'Pending',
      },
      {
        'name': 'Rohan Kumar',
        'phone': '9988776655',
        'parentPhone': '9988776611',
        'danceStyles': jsonEncode(['Bollywood', 'Zumba']),
        'batchTiming': '6:00 PM - 7:00 PM (Evening)',
        'joiningDate': '2025-11-15',
        'monthlyFee': 1200.0,
        'dueDay': 10,
        'status': 'Overdue',
      },
      {
        'name': 'Priya Singh',
        'phone': '9554433221',
        'parentPhone': '9554433200',
        'danceStyles': jsonEncode(['Aerobics', 'Contemporary']),
        'batchTiming': '7:00 AM - 8:00 AM (Morning)',
        'joiningDate': '2026-03-05',
        'monthlyFee': 1600.0,
        'dueDay': 5,
        'status': 'Active',
      },
    ];

    for (var s in students) {
      final studentId = await db.insert('students', s);

      // Add sample ledger entries for each student
      if (s['name'] == 'Aarav Sharma') {
        await db.insert('ledger', {
          'studentId': studentId,
          'monthYear': 'Aug 2026',
          'amountDue': 1500.0,
          'amountPaid': 1500.0,
          'paymentDate': '2026-08-04',
          'paymentMode': 'UPI',
          'status': 'Paid',
          'transactionRef': 'UPI/20260804/99128',
          'notes': 'Paid via PhonePe',
        });
        await db.insert('ledger', {
          'studentId': studentId,
          'monthYear': 'Jul 2026',
          'amountDue': 1500.0,
          'amountPaid': 1500.0,
          'paymentDate': '2026-07-05',
          'paymentMode': 'Cash',
          'status': 'Paid',
          'transactionRef': 'CASH-JUL-05',
          'notes': 'Handed in counter',
        });
      } else if (s['name'] == 'Ananya Verma') {
        await db.insert('ledger', {
          'studentId': studentId,
          'monthYear': 'Aug 2026',
          'amountDue': 1800.0,
          'amountPaid': 0.0,
          'paymentDate': '',
          'paymentMode': 'Cash',
          'status': 'Pending',
          'transactionRef': '',
          'notes': 'Due by 5th Aug',
        });
      } else if (s['name'] == 'Rohan Kumar') {
        await db.insert('ledger', {
          'studentId': studentId,
          'monthYear': 'Jul 2026',
          'amountDue': 1200.0,
          'amountPaid': 0.0,
          'paymentDate': '',
          'paymentMode': 'UPI',
          'status': 'Overdue',
          'transactionRef': '',
          'notes': 'Overdue penalty applicable',
        });
      }
    }
  }
}
