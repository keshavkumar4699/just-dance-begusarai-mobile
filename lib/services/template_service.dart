import '../models/models.dart';
import '../utils/date_utils.dart';

/// Resolves {placeholders} in WhatsApp templates.
/// Unresolvable / empty placeholders are dropped automatically.
class TemplateService {
  /// Builds the placeholder map for a student.
  static Map<String, String> valuesFor({
    required Student student,
    required String studio,
    required String address,
    required int cyclePrice,
    required String planName,
    required String courseName,
    required String? paidTill,
    required int due,
    required String today,
  }) {
    return {
      'name': student.name,
      'id': student.jdNo,
      'plan': planName,
      'course': courseName,
      'validTill': paidTill != null ? Dates.display(paidTill) : '--',
      'amount': '',
      'due': due > 0 ? Money.fmt(due) : '',
      'month': Dates.monthLabel(today),
      'studio': studio,
      'address': address,
    };
  }

  /// Fills a template; empty placeholders and leftover {tokens} are removed.
  static String fill(String template, Map<String, String> values) {
    var text = template;
    for (final e in values.entries) {
      final v = e.value.trim();
      text = v.isEmpty ? text.replaceAll('{${e.key}}', '') : text.replaceAll('{${e.key}}', v);
    }
    // Drop any remaining placeholders (e.g. amount left empty by design).
    text = text.replaceAll(RegExp(r'\{[a-zA-Z]+\}'), '');
    return text.replaceAll(RegExp(r'\s{2,}'), ' ').replaceAll(' ,', ',').trim();
  }

  /// Previews a template with dummy values so the owner can self-test.
  static String preview(String template, {required String studio, required String address}) {
    final dummy = {
      'name': 'Rahul Kumar',
      'id': 'JD-001',
      'plan': 'Monthly',
      'course': 'Strength Training',
      'validTill': Dates.display(Dates.fmt(Dates.addMonths(DateTime.now(), 1))),
      'amount': Money.fmt(1200),
      'due': Money.fmt(1200),
      'month': Dates.monthLabel(Dates.todayStr()),
      'studio': studio,
      'address': address,
    };
    return fill(template, dummy);
  }
}
