/// Calendar-safe date helpers. All dates are handled as 'yyyy-MM-dd' strings.
class Dates {
  static String todayStr() => fmt(DateTime.now());

  static String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parse(String s) {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static String today() => todayStr();

  /// '12 Sep 2026'
  static String display(String s) {
    final d = parse(s);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// '12 Sep'
  static String displayShort(String s) {
    final d = parse(s);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  /// 'Aug 2026'
  static String monthLabel(String s) {
    final d = parse(s);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  /// '2026-08' key for month grouping.
  static String monthKey(String s) {
    final d = parse(s);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  /// Full months between two dates (counts month boundaries).
  static int monthsBetween(DateTime from, DateTime to) {
    if (to.isBefore(from)) return -monthsBetween(to, from);
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  /// Calendar-safe: Jan 31 + 1 month = Feb 28.
  static DateTime addMonths(DateTime d, int months) {
    if (months == 0) return d;
    final total = d.month - 1 + months;
    var y = d.year + (total ~/ 12);
    var m = total % 12;
    if (m < 0) {
      m += 12;
      y -= 1;
    }
    final lastDay = DateTime(y, m + 2, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(y, m + 1, day);
  }

  static int daysBetween(DateTime a, DateTime b) => a.difference(b).inDays;

  /// Number of days from [from] to [to] inclusive.
  static int daySpan(String from, String to) {
    final f = DateTime(parse(from).year, parse(from).month, parse(from).day);
    final t = DateTime(parse(to).year, parse(to).month, parse(to).day);
    return t.difference(f).inDays + 1;
  }

  /// All date strings (inclusive) between two dates.
  static List<String> eachDay(String from, String to) {
    final f = parse(from);
    final t = parse(to);
    final out = <String>[];
    var cur = DateTime(f.year, f.month, f.day);
    while (!cur.isAfter(t)) {
      out.add(fmt(cur));
      cur = cur.add(const Duration(days: 1));
    }
    return out;
  }
}

/// Money helpers (rupees, whole numbers).
class Money {
  static String fmt(int amount) {
    final s = amount.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final rem = s.length - 1 - i;
      if (rem > 0 && rem % 3 == 0 && i != 0) buf.write(',');
    }
    return '₹${amount < 0 ? '-' : ''}$buf';
  }
}

/// Phone helpers (Indian 10-digit mobile).
class Phones {
  static bool valid(String mobile) =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(mobile.trim());

  /// wa.me needs country code 91 prefix.
  static String waNumber(String mobile) {
    final digits = mobile.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '91$digits';
    return digits;
  }

  static String tel(String mobile) => 'tel:${mobile.trim().replaceAll(RegExp(r'\D'), '')}';
}

/// Aadhar validation: 12 digits, not starting with 0 or 1.
class Aadhar {
  static bool valid(String value) {
    final v = value.trim();
    if (v.isEmpty) return true; // optional
    if (!RegExp(r'^\d{12}$').hasMatch(v)) return false;
    return !v.startsWith('0') && !v.startsWith('1');
  }
}

/// Category auto chip based on age at admission.
/// <12 KID'S, 12-24 BOYS/GIRLS, 25+ MALE/FEMALE.
String categoryFor({DateTime? dob, DateTime? on}) {
  if (dob == null) return '';
  final ref = on ?? DateTime.now();
  var age = ref.year - dob.year;
  if (ref.month < dob.month || (ref.month == dob.month && ref.day < dob.day)) age--;
  if (age < 12) return "KID'S";
  if (age < 25) return age < 18 ? 'BOYS/GIRLS' : 'BOYS/GIRLS';
  return 'MALE/FEMALE';
}

/// Age in years.
int? ageAt(DateTime? dob, DateTime? on) {
  if (dob == null) return null;
  final ref = on ?? DateTime.now();
  var age = ref.year - dob.year;
  if (ref.month < dob.month || (ref.month == dob.month && ref.day < dob.day)) age--;
  return age;
}
