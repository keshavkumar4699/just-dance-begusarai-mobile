/// Just Dance — pure helpers: calendar-safe date math, money format,
/// validators, ID generation. No Flutter imports (unit-test friendly).
library;

/// Calendar-safe addMonths: Jan 31 + 1mo -> Feb 28/29 (clamped, not overflowed).
DateTime addMonths(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final y = total ~/ 12;
  final m = total % 12 + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  final day = d.day > lastDay ? lastDay : d.day;
  return DateTime(y, m, day);
}

/// Number of completed month-steps from [start] to [end] (both date-only).
/// i.e. the largest k such that addMonths(start, k) <= end.
int monthDiff(DateTime start, DateTime end) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  if (e.isBefore(s)) return -1;
  var k = (e.year - s.year) * 12 + (e.month - s.month);
  while (addMonths(s, k).isAfter(e)) {
    k--;
  }
  return k < 0 ? 0 : k;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole days from [from] to [to] (date-only safe).
int daysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inDays;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// "12 Sep" / "12 Sep 2026" when the year differs from current.
String fmtDate(DateTime? d, {bool forceYear = false}) {
  if (d == null) return '—';
  final now = DateTime.now();
  final showYear = forceYear || d.year != now.year;
  return '${d.day} ${_months[d.month - 1]}${showYear ? ' ${d.year}' : ''}';
}

/// "Sep 2026" — ledger month label.
String monthLabel(DateTime d) => '${_months[d.month - 1]} ${d.year}';

/// ₹ formatting: 1500 -> "₹1,500", 1500.5 -> "₹1,500.50".
String fmtMoney(num v, {bool sign = false}) {
  final neg = v < 0;
  final abs = v.abs();
  final isInt = abs == abs.roundToDouble();
  final s = isInt
      ? _groupDigits(abs.round())
      : abs.toStringAsFixed(2);
  final prefix = neg ? '-₹' : (sign ? '+₹' : '₹');
  return '$prefix$s';
}

/// Indian digit grouping: 1234567 -> 12,34,567.
String _groupDigits(int v) {
  final s = v.toString();
  if (s.length <= 3) return s;
  final head = s.substring(0, s.length - 3);
  final tail = s.substring(s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < head.length; i++) {
    buf.write(head[i]);
    final remaining = head.length - (i + 1);
    if (remaining > 0 && remaining % 2 == 0) buf.write(',');
  }
  buf.write(',');
  return buf.toString() + tail;
}

// ---------- Validators (return error string or null) ----------

String? validateName(String? v) {
  if (v == null || v.trim().isEmpty) return 'Name is required';
  return null;
}

String? validateMobile(String? v, {bool required = true}) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return required ? 'Mobile number is required' : null;
  if (!RegExp(r'^\d{10}$').hasMatch(s)) return 'Enter a 10-digit mobile number';
  return null;
}

/// Aadhar: optional; if given must be 12 digits and not start with 0 or 1.
String? validateAadhar(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return null;
  if (!RegExp(r'^\d{12}$').hasMatch(s)) return 'Aadhar must be 12 digits';
  if (s.startsWith('0') || s.startsWith('1')) {
    return 'Aadhar cannot start with 0 or 1';
  }
  return null;
}

String? validateDob(DateTime? d) {
  if (d == null) return null; // optional
  if (!dateOnly(d).isBefore(dateOnly(DateTime.now()))) {
    return 'Date of birth cannot be in the future';
  }
  return null;
}

String? validatePin(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return null;
  if (!RegExp(r'^\d{6}$').hasMatch(s)) return 'PIN must be 6 digits';
  return null;
}

/// Positive amount check (₹0 / negative rejected).
String? validateAmount(String? v, {bool required = true}) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return required ? 'Enter an amount' : null;
  final n = double.tryParse(s);
  if (n == null) return 'Enter a valid number';
  if (n <= 0) return 'Amount must be more than ₹0';
  return null;
}

/// Discount validation: percent capped 0–100, ₹ never exceeds [due].
String? validateDiscount(String? v, {required bool isPercent, required num due}) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return null;
  final n = double.tryParse(s);
  if (n == null) return 'Enter a valid number';
  if (n < 0) return 'Discount cannot be negative';
  if (isPercent && n > 100) return 'Percent cannot exceed 100';
  if (!isPercent && n > due) return 'Discount cannot be more than the due';
  return null;
}

/// Age from DOB in whole years.
int? ageFromDob(DateTime? dob) {
  if (dob == null) return null;
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (DateTime(now.year, dob.month, dob.day).isAfter(dateOnly(now))) age--;
  return age;
}

/// Auto category chip: <12 KID'S; 12–24 BOYS/GIRLS; 25+ MALE/FEMALE.
String categoryFor(DateTime? dob, String? gender) {
  final age = ageFromDob(dob);
  if (age == null) return '—';
  final g = (gender ?? '').toLowerCase();
  if (age < 12) return "KID'S";
  if (age <= 24) return g.startsWith('f') ? 'GIRLS' : 'BOYS';
  return g.startsWith('f') ? 'FEMALE' : 'MALE';
}

/// Normalise to 10-digit national number (strip +91 / 91 prefix / spaces).
String normalizeMobile(String raw) {
  var s = raw.replaceAll(RegExp(r'\D'), '');
  if (s.length == 12 && s.startsWith('91')) s = s.substring(2);
  if (s.length == 11 && s.startsWith('0')) s = s.substring(1);
  return s;
}

/// Template fill: replaces {tokens}; tokens with empty values are removed,
/// then dangling separators (double spaces, " ()", ": .") are cleaned up.
String fillTemplate(String template, Map<String, String?> values) {
  var out = template;
  values.forEach((token, value) {
    out = out.replaceAll(token, (value ?? '').trim());
  });
  // Drop empty parenthesis pairs and collapse whitespace/leftover separators.
  out = out.replaceAll('()', '');
  out = out.replaceAll(RegExp(r'\s+'), ' ');
  out = out.replaceAll(RegExp(r'\s+([.,;:!?)])'), r'$1');
  out = out.replaceAll(RegExp(r'([(])\s+'), r'$1');
  return out.trim();
}
