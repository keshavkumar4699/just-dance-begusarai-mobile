import 'package:url_launcher/url_launcher.dart';
import '../models/student.dart';
import '../models/ledger_entry.dart';
import 'fee_engine.dart';
import '../constants.dart';

class WhatsAppService {
  static String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    return cleaned;
  }

  static Future<bool> sendPaymentReminder({
    required Student student,
    required String monthYear,
    required double amountDue,
  }) async {
    final phone = _cleanPhoneNumber(student.phone.isNotEmpty ? student.phone : student.parentPhone);
    if (phone.isEmpty) return false;

    final String message = 
      "Dear ${student.name},\n\n"
      "Greetings from *${AppConstants.appName} (${AppConstants.studioAddress})*! 🩰\n\n"
      "This is a gentle reminder regarding your pending fee for * $monthYear*.\n"
      "• Amount Due: *${FeeEngine.formatCurrency(amountDue)}*\n"
      "• Due Day: ${student.dueDay}th of the month\n\n"
      "Kindly pay at the earliest via Cash or UPI to avoid late charges.\n\n"
      "Thank you,\n"
      "*Management - Just Dance Academy*";

    final Uri url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> sendPaymentReceipt({
    required Student student,
    required LedgerEntry entry,
  }) async {
    final phone = _cleanPhoneNumber(student.phone.isNotEmpty ? student.phone : student.parentPhone);
    if (phone.isEmpty) return false;

    final String message = 
      "✨ *FEES PAYMENT RECEIPT* ✨\n"
      "*${AppConstants.appName}*\n"
      "----------------------------------\n"
      "Student Name: *${student.name}*\n"
      "Month/Period: *${entry.monthYear}*\n"
      "Amount Paid: *${FeeEngine.formatCurrency(entry.amountPaid)}*\n"
      "Payment Mode: *${entry.paymentMode}*\n"
      "Date: *${entry.paymentDate}*\n"
      "Ref / Txn ID: *${entry.transactionRef.isNotEmpty ? entry.transactionRef : 'N/A'}*\n"
      "----------------------------------\n"
      "Status: *${entry.status.toUpperCase()}* ✅\n\n"
      "Thank you for dancing with us! Keep shining ⭐";

    final Uri url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
