class LedgerEntry {
  final int? id;
  final int studentId;
  final DateTime date;
  final String type; // PAYMENT, ADMISSION_FEE_PAID, AUTO_CREDIT_ADJUST, PT_PAYMENT, PLAN_CHANGE, NOTE
  final String monthLabel;
  final double dueAmount;
  final double paidAmount;
  final double balanceOrCredit;
  final String mode; // Cash, UPI
  final String? note;

  LedgerEntry({
    this.id,
    required this.studentId,
    required this.date,
    required this.type,
    required this.monthLabel,
    this.dueAmount = 0.0,
    this.paidAmount = 0.0,
    this.balanceOrCredit = 0.0,
    this.mode = 'Cash',
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'type': type,
      'monthLabel': monthLabel,
      'dueAmount': dueAmount,
      'paidAmount': paidAmount,
      'balanceOrCredit': balanceOrCredit,
      'mode': mode,
      'note': note,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      studentId: map['studentId'] as int,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      monthLabel: map['monthLabel'] as String? ?? '',
      dueAmount: (map['dueAmount'] as num? ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] as num? ?? 0).toDouble(),
      balanceOrCredit: (map['balanceOrCredit'] as num? ?? 0).toDouble(),
      mode: map['mode'] as String? ?? 'Cash',
      note: map['note'] as String?,
    );
  }
}
