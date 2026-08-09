import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/student.dart';
import 'fee_engine.dart';

class InvoiceService {
  static Future<void> shareInvoice({
    required BuildContext context,
    required Student student,
    required double paidAmount,
    required double planPrice,
    required double admissionFee,
    required String paymentMode,
  }) async {
    try {
      final eval = FeeEngine.evaluateStudent(student);
      final dateStr = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

      final summaryText = '''
🧾 STUDIO CROW — FEE INVOICE
---------------------------------------
Studio: Studio Crow Begusarai
Date: $dateStr
Student Name: ${student.name}
ID No: ${student.jdNo}
---------------------------------------
Plan: ${student.plan} (₹${planPrice.toStringAsFixed(0)})
Admission Fee: ₹${admissionFee.toStringAsFixed(0)}
Paid Amount: ₹${paidAmount.toStringAsFixed(0)} ($paymentMode)
Balance / Advance: ${eval.creditAmount > 0 ? "+₹${eval.creditAmount.toStringAsFixed(0)} Advance" : "₹${eval.dueAmount.toStringAsFixed(0)} Due"}
---------------------------------------
– Rahul Raja Sir 🕺
''';

      final tempDir = await getTemporaryDirectory();
      final textFilePath = p.join(tempDir.path, '${student.jdNo}_invoice.txt');
      final file = File(textFilePath);
      await file.writeAsString(summaryText);

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: '🧾 ${student.name} ji, aapki Studio Crow invoice receipt attached hai.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice share nahi ho saka.')),
        );
      }
    }
  }
}
