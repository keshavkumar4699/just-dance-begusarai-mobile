/// Just Dance — data models (SQLite rows <-> Dart objects).
library;

class Student {
  int id;
  String jdNo;
  String name;
  String fatherName;
  String motherName;
  String photoPath;
  // Permanent address
  String permVillage, permPO, permDist, permPin;
  bool corrSame;
  String corrVillage, corrPO, corrDist, corrPin;
  // Identity
  String aadhar;
  DateTime? dob;
  String gender; // 'Male' | 'Female' | ''
  String religion;
  String nationality;
  String maritalStatus; // 'Married' | 'Unmarried' | ''
  // Contact
  String mobile;
  String altMobile;
  // Membership
  DateTime admissionDate;
  int? planId;
  bool admissionFeeEnabled;
  bool admissionFeePaid;
  int monthsCovered; // full monthly cycles paid
  double cycleBalance; // remaining due on an open partial cycle (derived)
  double credit; // advance pool
  DateTime? lastVisitDate;
  bool isBlocked;
  // Personal training (recharge-based)
  bool ptEnabled;
  int ptSessions;
  int ptSessionsDone;
  double ptSessionPrice;
  double ptPaid;
  String ptTiming;
  String ptDays; // e.g. "Mon,Wed,Fri"
  DateTime createdAt, updatedAt;

  Student({
    this.id = 0,
    this.jdNo = '',
    this.name = '',
    this.fatherName = '',
    this.motherName = '',
    this.photoPath = '',
    this.permVillage = '',
    this.permPO = '',
    this.permDist = '',
    this.permPin = '',
    this.corrSame = true,
    this.corrVillage = '',
    this.corrPO = '',
    this.corrDist = '',
    this.corrPin = '',
    this.aadhar = '',
    this.dob,
    this.gender = '',
    this.religion = '',
    this.nationality = 'Indian',
    this.maritalStatus = '',
    this.mobile = '',
    this.altMobile = '',
    DateTime? admissionDate,
    this.planId,
    this.admissionFeeEnabled = true,
    this.admissionFeePaid = false,
    this.monthsCovered = 0,
    this.cycleBalance = 0,
    this.credit = 0,
    this.lastVisitDate,
    this.isBlocked = false,
    this.ptEnabled = false,
    this.ptSessions = 0,
    this.ptSessionsDone = 0,
    this.ptSessionPrice = 0,
    this.ptPaid = 0,
    this.ptTiming = '',
    this.ptDays = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : admissionDate = admissionDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'jdNo': jdNo,
        'name': name,
        'fatherName': fatherName,
        'motherName': motherName,
        'photoPath': photoPath,
        'permVillage': permVillage,
        'permPO': permPO,
        'permDist': permDist,
        'permPin': permPin,
        'corrSame': corrSame ? 1 : 0,
        'corrVillage': corrVillage,
        'corrPO': corrPO,
        'corrDist': corrDist,
        'corrPin': corrPin,
        'aadhar': aadhar,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'religion': religion,
        'nationality': nationality,
        'maritalStatus': maritalStatus,
        'mobile': mobile,
        'altMobile': altMobile,
        'admissionDate': admissionDate.toIso8601String(),
        'planId': planId,
        'admissionFeeEnabled': admissionFeeEnabled ? 1 : 0,
        'admissionFeePaid': admissionFeePaid ? 1 : 0,
        'monthsCovered': monthsCovered,
        'cycleBalance': cycleBalance,
        'credit': credit,
        'lastVisitDate': lastVisitDate?.toIso8601String(),
        'isBlocked': isBlocked ? 1 : 0,
        'ptEnabled': ptEnabled ? 1 : 0,
        'ptSessions': ptSessions,
        'ptSessionsDone': ptSessionsDone,
        'ptSessionPrice': ptSessionPrice,
        'ptPaid': ptPaid,
        'ptTiming': ptTiming,
        'ptDays': ptDays,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Student.fromMap(Map<String, Object?> m) => Student(
        id: m['id'] as int,
        jdNo: (m['jdNo'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        fatherName: (m['fatherName'] ?? '') as String,
        motherName: (m['motherName'] ?? '') as String,
        photoPath: (m['photoPath'] ?? '') as String,
        permVillage: (m['permVillage'] ?? '') as String,
        permPO: (m['permPO'] ?? '') as String,
        permDist: (m['permDist'] ?? '') as String,
        permPin: (m['permPin'] ?? '') as String,
        corrSame: (m['corrSame'] as int? ?? 1) == 1,
        corrVillage: (m['corrVillage'] ?? '') as String,
        corrPO: (m['corrPO'] ?? '') as String,
        corrDist: (m['corrDist'] ?? '') as String,
        corrPin: (m['corrPin'] ?? '') as String,
        aadhar: (m['aadhar'] ?? '') as String,
        dob: m['dob'] != null ? DateTime.parse(m['dob'] as String) : null,
        gender: (m['gender'] ?? '') as String,
        religion: (m['religion'] ?? '') as String,
        nationality: (m['nationality'] ?? 'Indian') as String,
        maritalStatus: (m['maritalStatus'] ?? '') as String,
        mobile: (m['mobile'] ?? '') as String,
        altMobile: (m['altMobile'] ?? '') as String,
        admissionDate: DateTime.parse(m['admissionDate'] as String),
        planId: m['planId'] as int?,
        admissionFeeEnabled: (m['admissionFeeEnabled'] as int? ?? 1) == 1,
        admissionFeePaid: (m['admissionFeePaid'] as int? ?? 0) == 1,
        monthsCovered: m['monthsCovered'] as int? ?? 0,
        cycleBalance: (m['cycleBalance'] as num?)?.toDouble() ?? 0,
        credit: (m['credit'] as num?)?.toDouble() ?? 0,
        lastVisitDate: m['lastVisitDate'] != null
            ? DateTime.parse(m['lastVisitDate'] as String)
            : null,
        isBlocked: (m['isBlocked'] as int? ?? 0) == 1,
        ptEnabled: (m['ptEnabled'] as int? ?? 0) == 1,
        ptSessions: m['ptSessions'] as int? ?? 0,
        ptSessionsDone: m['ptSessionsDone'] as int? ?? 0,
        ptSessionPrice: (m['ptSessionPrice'] as num?)?.toDouble() ?? 0,
        ptPaid: (m['ptPaid'] as num?)?.toDouble() ?? 0,
        ptTiming: (m['ptTiming'] ?? '') as String,
        ptDays: (m['ptDays'] ?? '') as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}

class Course {
  int id;
  String name;
  double fee; // monthly fee
  String description;
  DateTime createdAt;
  Course({this.id = 0, this.name = '', this.fee = 0, this.description = '', DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'name': name,
        'fee': fee,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };
  factory Course.fromMap(Map<String, Object?> m) => Course(
        id: m['id'] as int,
        name: m['name'] as String,
        fee: (m['fee'] as num).toDouble(),
        description: (m['description'] ?? '') as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

class Batch {
  int id;
  int courseId;
  String name;
  String daysInfo;
  String duration; // e.g. "1 hour", "2 hours"
  Batch({this.id = 0, this.courseId = 0, this.name = '', this.daysInfo = '', this.duration = ''});
  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'courseId': courseId,
        'name': name,
        'daysInfo': daysInfo,
        'duration': duration
      };
  factory Batch.fromMap(Map<String, Object?> m) => Batch(
      id: m['id'] as int,
      courseId: m['courseId'] as int,
      name: m['name'] as String,
      daysInfo: (m['daysInfo'] ?? '') as String,
      duration: (m['duration'] ?? '') as String);
}

class BatchTiming {
  int id;
  int batchId;
  String label;
  String startTime; // "06:00"
  String endTime; // "07:00"
  BatchTiming({this.id = 0, this.batchId = 0, this.label = '', this.startTime = '', this.endTime = ''});
  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'batchId': batchId,
        'label': label,
        'startTime': startTime,
        'endTime': endTime
      };
  factory BatchTiming.fromMap(Map<String, Object?> m) => BatchTiming(
      id: m['id'] as int,
      batchId: m['batchId'] as int,
      label: m['label'] as String,
      startTime: (m['startTime'] ?? '') as String,
      endTime: (m['endTime'] ?? '') as String);
}

class Plan {
  int id;
  String name;
  int months;
  String discountType; // 'rs' | 'percent' | ''
  double discountValue;
  Plan({this.id = 0, this.name = '', this.months = 1, this.discountType = '', this.discountValue = 0});
  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'name': name,
        'months': months,
        'discountType': discountType,
        'discountValue': discountValue
      };
  factory Plan.fromMap(Map<String, Object?> m) => Plan(
      id: m['id'] as int,
      name: m['name'] as String,
      months: m['months'] as int,
      discountType: (m['discountType'] ?? '') as String,
      discountValue: (m['discountValue'] as num?)?.toDouble() ?? 0);
}

class StudentCourse {
  int id;
  int studentId, courseId, batchId, timingId;
  bool isPrimary;
  StudentCourse({this.id = 0, this.studentId = 0, this.courseId = 0, this.batchId = 0, this.timingId = 0, this.isPrimary = false});
  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'studentId': studentId,
        'courseId': courseId,
        'batchId': batchId,
        'timingId': timingId,
        'isPrimary': isPrimary ? 1 : 0
      };
  factory StudentCourse.fromMap(Map<String, Object?> m) => StudentCourse(
      id: m['id'] as int,
      studentId: m['studentId'] as int,
      courseId: m['courseId'] as int,
      batchId: m['batchId'] as int,
      timingId: m['timingId'] as int,
      isPrimary: (m['isPrimary'] as int? ?? 0) == 1);
}

class AttendanceRow {
  int id;
  int studentId, courseId;
  DateTime date; // date-only
  DateTime markedAt;
  AttendanceRow({this.id = 0, this.studentId = 0, this.courseId = 0, DateTime? date, DateTime? markedAt})
      : date = date ?? DateTime.now(),
        markedAt = markedAt ?? DateTime.now();
  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'studentId': studentId,
        'courseId': courseId,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'markedAt': markedAt.toIso8601String()
      };
  factory AttendanceRow.fromMap(Map<String, Object?> m) => AttendanceRow(
      id: m['id'] as int,
      studentId: m['studentId'] as int,
      courseId: m['courseId'] as int,
      date: DateTime.parse(m['date'] as String),
      markedAt: DateTime.parse(m['markedAt'] as String));
}

class LedgerEntry {
  int id;
  int studentId;
  DateTime date;
  String type; // PAYMENT / ADMISSION_FEE_PAID / AUTO_CREDIT_ADJUST / PT_PAYMENT / PLAN_CHANGE / NOTE
  String monthLabel; // e.g. "Sep 2026"
  double dueAmount; // total due BEFORE this entry (display)
  double paidAmount;
  double balanceOrCredit; // after: >0 baki, <0 advance, 0 settled
  String mode; // Cash | UPI | ''
  String note;
  double cyclePrice; // snapshot of per-cycle price used (PAYMENT / AUTO_CREDIT_ADJUST)
  double discount; // discount value applied inside this entry

  LedgerEntry({
    this.id = 0,
    this.studentId = 0,
    DateTime? date,
    this.type = '',
    this.monthLabel = '',
    this.dueAmount = 0,
    this.paidAmount = 0,
    this.balanceOrCredit = 0,
    this.mode = '',
    this.note = '',
    this.cyclePrice = 0,
    this.discount = 0,
  }) : date = date ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id == 0 ? null : id,
        'studentId': studentId,
        'date': date.toIso8601String(),
        'type': type,
        'monthLabel': monthLabel,
        'dueAmount': dueAmount,
        'paidAmount': paidAmount,
        'balanceOrCredit': balanceOrCredit,
        'mode': mode,
        'note': note,
        'cyclePrice': cyclePrice,
        'discount': discount,
      };
  factory LedgerEntry.fromMap(Map<String, Object?> m) => LedgerEntry(
      id: m['id'] as int,
      studentId: m['studentId'] as int,
      date: DateTime.parse(m['date'] as String),
      type: m['type'] as String,
      monthLabel: (m['monthLabel'] ?? '') as String,
      dueAmount: (m['dueAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (m['paidAmount'] as num?)?.toDouble() ?? 0,
      balanceOrCredit: (m['balanceOrCredit'] as num?)?.toDouble() ?? 0,
      mode: (m['mode'] ?? '') as String,
      note: (m['note'] ?? '') as String,
      cyclePrice: (m['cyclePrice'] as num?)?.toDouble() ?? 0,
      discount: (m['discount'] as num?)?.toDouble() ?? 0);
}

/// Owner-editable studio profile (drives ID cards, invoices, templates).
class StudioInfo {
  String name;
  String director;
  String phone;
  String whatsapp;
  String instagram;
  String address;
  String photoPath; // owner avatar / logo override ('' => bundled logo)
  StudioInfo({
    this.name = 'My Studio',
    this.director = '',
    this.phone = '',
    this.whatsapp = '',
    this.instagram = '',
    this.address = '',
    this.photoPath = '',
  });

  Map<String, Object?> toJson() => {
        'name': name,
        'director': director,
        'phone': phone,
        'whatsapp': whatsapp,
        'instagram': instagram,
        'address': address,
        'photoPath': photoPath,
      };
  factory StudioInfo.fromJson(Map<String, Object?> m) => StudioInfo(
        name: (m['name'] ?? 'My Studio') as String,
        director: (m['director'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        whatsapp: (m['whatsapp'] ?? '') as String,
        instagram: (m['instagram'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        photoPath: (m['photoPath'] ?? '') as String,
      );
}
