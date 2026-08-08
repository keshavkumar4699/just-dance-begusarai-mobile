class LedgerEntry {
  final int? id;
  final int studentId;
  final String monthYear; // e.g. "Aug 2026"
  final double amountDue;
  final double amountPaid;
  final String paymentDate;
  final String paymentMode; // 'Cash', 'UPI', 'Card', 'Bank Transfer'
  final String status; // 'Paid', 'Partial', 'Pending', 'Overdue'
  final String transactionRef;
  final String notes;

  LedgerEntry({
    this.id,
    required this.studentId,
    required this.monthYear,
    required this.amountDue,
    required this.amountPaid,
    required this.paymentDate,
    this.paymentMode = 'Cash',
    required this.status,
    this.transactionRef = '',
    this.notes = '',
  });

  double get balanceRemaining => amountDue - amountPaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'monthYear': monthYear,
      'amountDue': amountDue,
      'amountPaid': amountPaid,
      'paymentDate': paymentDate,
      'paymentMode': paymentMode,
      'status': status,
      'transactionRef': transactionRef,
      'notes': notes,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      studentId: map['studentId'] as int,
      monthYear: map['monthYear'] ?? '',
      amountDue: (map['amountDue'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] ?? '',
      paymentMode: map['paymentMode'] ?? 'Cash',
      status: map['status'] ?? 'Pending',
      transactionRef: map['transactionRef'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
