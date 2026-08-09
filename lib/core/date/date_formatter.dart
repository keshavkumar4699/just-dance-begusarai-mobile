import 'package:intl/intl.dart';

/// Studio Crow Date Helper Utilities
abstract class DateFormatter {
  static final DateFormat _indianFormat = DateFormat('dd MMM yyyy');

  /// Formats DateTime into '09 Aug 2026'
  static String formatIndian(DateTime? date) {
    if (date == null) return 'N/A';
    return _indianFormat.format(date);
  }

  /// Calculates member category based on age:
  /// Under 12: KID'S
  /// 12-24: BOYS / GIRLS (based on gender)
  /// 25+: MALE / FEMALE (based on gender)
  static String calculateCategory(DateTime? dob, String gender) {
    if (dob == null) return 'MALE';
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    final isFemale = gender.toUpperCase() == 'FEMALE';

    if (age < 12) {
      return "KID'S";
    } else if (age <= 24) {
      return isFemale ? 'GIRLS' : 'BOYS';
    } else {
      return isFemale ? 'FEMALE' : 'MALE';
    }
  }

  /// Calendar-safe month addition
  static DateTime addMonths(DateTime from, int months) {
    var year = from.year + (from.month + months - 1) ~/ 12;
    var month = (from.month + months - 1) % 12 + 1;
    var day = from.day;
    var lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfTargetMonth) {
      day = lastDayOfTargetMonth;
    }
    return DateTime(year, month, day);
  }
}
