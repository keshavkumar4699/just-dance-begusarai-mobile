/// Just Dance — one-tap WhatsApp + dialer helpers (owner presses send;
/// no automation, no Business API).
library;

import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../data/models.dart';
import '../data/store.dart';

class WhatsAppService {
  WhatsAppService._();
  static final WhatsAppService instance = WhatsAppService._();

  /// Opens the student's WhatsApp chat with [message] pre-filled.
  /// Returns false when WhatsApp (or the link) could not be opened.
  Future<bool> openChat(String mobile, String message) async {
    final number = kCountryCode + normalizeMobile(mobile);
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> call(String mobile) async {
    final uri = Uri.parse('tel:${normalizeMobile(mobile)}');
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  /// Builds a template message for [student]; empty placeholders are dropped.
  String build(String templateKey, AppStore store, Student s,
      {String? amount, String? due, String? month}) {
    final st = store.statusOf(s);
    final plan = store.planById(s.planId);
    final courses = store.coursesOf(s.id);
    final courseName = courses.isEmpty
        ? ''
        : (store.courseById(courses.first.courseId)?.name ?? '');
    return fillTemplate(store.templates[templateKey] ?? '', {
      '{name}': s.name.split(' ').first,
      '{id}': s.jdNo,
      '{plan}': plan?.name ?? '',
      '{course}': courseName,
      '{validTill}': fmtDate(st.paidTill, forceYear: true),
      '{amount}': amount ?? '',
      '{due}': due ?? (st.hasDue ? fmtMoney(st.due) : ''),
      '{month}': month ?? monthLabel(DateTime.now()),
      '{studio}': store.studio.name,
      '{address}': store.studio.address,
    });
  }
}
