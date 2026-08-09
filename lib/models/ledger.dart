enum LedgerType {
  payment,
  admissionFeePaid,
  autoCreditAdjust,
  ptPayment,
  planChange,
  note,
}

class Ledger {
  final int? id;
  final int studentId;
  final DateTime date;
  final LedgerType type;
  final String? monthLabel;
  final double dueAmount;
  final double paidAmount;
  final double balanceOrCredit;
  final String? mode;
  final String? note;

  Ledger({
    this.id,
    required this.studentId,
    required this.date,
    required this.type,
    this.monthLabel,
    this.dueAmount = 0,
    this.paidAmount = 0,
    this.balanceOrCredit = 0,
    this.mode,
    this.note,
  });

  factory Ledger.fromMap(Map<String, dynamic> map) {
    return Ledger(
      id: map['id'] as int?,
      studentId: map['studentId'] as int,
      date: DateTime.parse(map['date'] as String),
      type: LedgerType.values.firstWhere(
        (e) => e.toString() == 'LedgerType.${map['type']}',
      ),
      monthLabel: map['monthLabel'] as String?,
      dueAmount: (map['dueAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      balanceOrCredit: (map['balanceOrCredit'] as num?)?.toDouble() ?? 0,
      mode: map['mode'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'type': type.name,
      'monthLabel': monthLabel,
      'dueAmount': dueAmount,
      'paidAmount': paidAmount,
      'balanceOrCredit': balanceOrCredit,
      'mode': mode,
      'note': note,
    };
  }
}