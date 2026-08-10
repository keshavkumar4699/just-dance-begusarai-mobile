import '../utils/date_utils.dart';
import '../constants.dart';

/// Student record (mirrors the students table).
class Student {
  int? id;
  final String jdNo;
  String name;
  String fatherName;
  String motherName;
  String photoPath;
  String permVillage, permPO, permDist, permPin;
  bool corrSame;
  String corrVillage, corrPO, corrDist, corrPin;
  String aadhar;
  String dob;
  String gender;
  String religion;
  String nationality;
  String maritalStatus;
  String mobile;
  String altMobile;
  String admissionDate;
  int? planId;
  bool admissionFeeEnabled;
  bool admissionFeePaid;
  int monthsCovered;
  int cycleBalance;
  int credit;
  String lastVisitDate;
  bool isBlocked;
  bool ptEnabled;
  int ptSessions;
  int ptSessionsDone;
  int ptSessionPrice;
  int ptPaid;
  String ptTiming;
  final String createdAt;
  String updatedAt;

  Student({
    this.id,
    required this.jdNo,
    required this.name,
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
    this.dob = '',
    this.gender = '',
    this.religion = '',
    this.nationality = 'Indian',
    this.maritalStatus = '',
    this.mobile = '',
    this.altMobile = '',
    required this.admissionDate,
    this.planId,
    this.admissionFeeEnabled = true,
    this.admissionFeePaid = false,
    this.monthsCovered = 0,
    this.cycleBalance = 0,
    this.credit = 0,
    this.lastVisitDate = '',
    this.isBlocked = false,
    this.ptEnabled = false,
    this.ptSessions = 0,
    this.ptSessionsDone = 0,
    this.ptSessionPrice = 0,
    this.ptPaid = 0,
    this.ptTiming = '',
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? Dates.todayStr(),
        updatedAt = updatedAt ?? Dates.todayStr();

  /// Date of last visit (or admission if never visited).
  String effectiveLastVisit() => lastVisitDate.isEmpty ? admissionDate : lastVisitDate;

  int get ptEarnings => ptSessionsDone * ptSessionPrice - ptPaid;

  Map<String, Object?> toMap() => {
        'id': id,
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
        'dob': dob,
        'gender': gender,
        'religion': religion,
        'nationality': nationality,
        'maritalStatus': maritalStatus,
        'mobile': mobile,
        'altMobile': altMobile,
        'admissionDate': admissionDate,
        'planId': planId,
        'admissionFeeEnabled': admissionFeeEnabled ? 1 : 0,
        'admissionFeePaid': admissionFeePaid ? 1 : 0,
        'monthsCovered': monthsCovered,
        'cycleBalance': cycleBalance,
        'credit': credit,
        'lastVisitDate': lastVisitDate,
        'isBlocked': isBlocked ? 1 : 0,
        'ptEnabled': ptEnabled ? 1 : 0,
        'ptSessions': ptSessions,
        'ptSessionsDone': ptSessionsDone,
        'ptSessionPrice': ptSessionPrice,
        'ptPaid': ptPaid,
        'ptTiming': ptTiming,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Student.fromMap(Map<String, Object?> m) => Student(
        id: m['id'] as int?,
        jdNo: m['jdNo'] as String? ?? '',
        name: m['name'] as String? ?? '',
        fatherName: m['fatherName'] as String? ?? '',
        motherName: m['motherName'] as String? ?? '',
        photoPath: m['photoPath'] as String? ?? '',
        permVillage: m['permVillage'] as String? ?? '',
        permPO: m['permPO'] as String? ?? '',
        permDist: m['permDist'] as String? ?? '',
        permPin: m['permPin'] as String? ?? '',
        corrSame: (m['corrSame'] as int? ?? 1) == 1,
        corrVillage: m['corrVillage'] as String? ?? '',
        corrPO: m['corrPO'] as String? ?? '',
        corrDist: m['corrDist'] as String? ?? '',
        corrPin: m['corrPin'] as String? ?? '',
        aadhar: m['aadhar'] as String? ?? '',
        dob: m['dob'] as String? ?? '',
        gender: m['gender'] as String? ?? '',
        religion: m['religion'] as String? ?? '',
        nationality: m['nationality'] as String? ?? 'Indian',
        maritalStatus: m['maritalStatus'] as String? ?? '',
        mobile: m['mobile'] as String? ?? '',
        altMobile: m['altMobile'] as String? ?? '',
        admissionDate: m['admissionDate'] as String? ?? Dates.todayStr(),
        planId: m['planId'] as int?,
        admissionFeeEnabled: (m['admissionFeeEnabled'] as int? ?? 1) == 1,
        admissionFeePaid: (m['admissionFeePaid'] as int? ?? 0) == 1,
        monthsCovered: m['monthsCovered'] as int? ?? 0,
        cycleBalance: m['cycleBalance'] as int? ?? 0,
        credit: m['credit'] as int? ?? 0,
        lastVisitDate: m['lastVisitDate'] as String? ?? '',
        isBlocked: (m['isBlocked'] as int? ?? 0) == 1,
        ptEnabled: (m['ptEnabled'] as int? ?? 0) == 1,
        ptSessions: m['ptSessions'] as int? ?? 0,
        ptSessionsDone: m['ptSessionsDone'] as int? ?? 0,
        ptSessionPrice: m['ptSessionPrice'] as int? ?? 0,
        ptPaid: m['ptPaid'] as int? ?? 0,
        ptTiming: m['ptTiming'] as String? ?? '',
        createdAt: m['createdAt'] as String? ?? Dates.todayStr(),
        updatedAt: m['updatedAt'] as String? ?? Dates.todayStr(),
      );

  Map<String, Object?> toJson() => toMap();
  factory Student.fromJson(Map<String, Object?> m) => Student.fromMap(m);
}

/// Course - user created, carries monthly fee.
class Course {
  int? id;
  String name;
  int fee;
  String description;
  final String createdAt;

  Course({this.id, required this.name, this.fee = 0, this.description = '', String? createdAt})
      : createdAt = createdAt ?? Dates.todayStr();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'fee': fee,
        'description': description,
        'createdAt': createdAt,
      };

  factory Course.fromMap(Map<String, Object?> m) => Course(
        id: m['id'] as int?,
        name: m['name'] as String? ?? '',
        fee: m['fee'] as int? ?? 0,
        description: m['description'] as String? ?? '',
        createdAt: m['createdAt'] as String? ?? '',
      );

  Map<String, Object?> toJson() => toMap();
  factory Course.fromJson(Map<String, Object?> m) => Course.fromMap(m);
}

/// Batch belongs to a course.
class Batch {
  int? id;
  final int courseId;
  String name;
  String daysInfo;

  Batch({this.id, required this.courseId, required this.name, this.daysInfo = ''});

  Map<String, Object?> toMap() => {
        'id': id,
        'courseId': courseId,
        'name': name,
        'daysInfo': daysInfo,
      };

  factory Batch.fromMap(Map<String, Object?> m) => Batch(
        id: m['id'] as int?,
        courseId: m['courseId'] as int? ?? 0,
        name: m['name'] as String? ?? '',
        daysInfo: m['daysInfo'] as String? ?? '',
      );

  Map<String, Object?> toJson() => toMap();
  factory Batch.fromJson(Map<String, Object?> m) => Batch.fromMap(m);
}

/// Timing belongs to a batch.
class Timing {
  int? id;
  final int batchId;
  String label;
  String startTime;
  String endTime;

  Timing({this.id, required this.batchId, required this.label, this.startTime = '', this.endTime = ''});

  Map<String, Object?> toMap() => {
        'id': id,
        'batchId': batchId,
        'label': label,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory Timing.fromMap(Map<String, Object?> m) => Timing(
        id: m['id'] as int?,
        batchId: m['batchId'] as int? ?? 0,
        label: m['label'] as String? ?? '',
        startTime: m['startTime'] as String? ?? '',
        endTime: m['endTime'] as String? ?? '',
      );

  Map<String, Object?> toJson() => toMap();
  factory Timing.fromJson(Map<String, Object?> m) => Timing.fromMap(m);
}

/// Plan - duration + discount.
class Plan {
  int? id;
  String name;
  int months;
  String discountType; // '₹' or '%'
  int discountValue;

  Plan({this.id, required this.name, this.months = 1, this.discountType = '%', this.discountValue = 0});

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'months': months,
        'discountType': discountType,
        'discountValue': discountValue,
      };

  factory Plan.fromMap(Map<String, Object?> m) => Plan(
        id: m['id'] as int?,
        name: m['name'] as String? ?? '',
        months: m['months'] as int? ?? 1,
        discountType: m['discountType'] as String? ?? '%',
        discountValue: m['discountValue'] as int? ?? 0,
      );

  Map<String, Object?> toJson() => toMap();
  factory Plan.fromJson(Map<String, Object?> m) => Plan.fromMap(m);
}

/// A student's course enrollment (batch + timing + fee snapshot).
class StudentCourse {
  int? id;
  final int studentId;
  final int courseId;
  final int batchId;
  final int timingId;
  bool isPrimary;
  final int feeSnapshot;

  StudentCourse({
    this.id,
    required this.studentId,
    required this.courseId,
    this.batchId = 0,
    this.timingId = 0,
    this.isPrimary = false,
    this.feeSnapshot = 0,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'studentId': studentId,
        'courseId': courseId,
        'batchId': batchId,
        'timingId': timingId,
        'isPrimary': isPrimary ? 1 : 0,
        'feeSnapshot': feeSnapshot,
      };

  factory StudentCourse.fromMap(Map<String, Object?> m) => StudentCourse(
        id: m['id'] as int?,
        studentId: m['studentId'] as int? ?? 0,
        courseId: m['courseId'] as int? ?? 0,
        batchId: m['batchId'] as int? ?? 0,
        timingId: m['timingId'] as int? ?? 0,
        isPrimary: (m['isPrimary'] as int? ?? 0) == 1,
        feeSnapshot: m['feeSnapshot'] as int? ?? 0,
      );

  Map<String, Object?> toJson() => toMap();
  factory StudentCourse.fromJson(Map<String, Object?> m) => StudentCourse.fromMap(m);
}

/// Attendance - insert-only immutable log.
class AttendanceRecord {
  int? id;
  final int studentId;
  final int courseId;
  final String date;
  final String markedAt;

  AttendanceRecord({this.id, required this.studentId, required this.courseId, required this.date, String? markedAt})
      : markedAt = markedAt ?? DateTime.now().toIso8601String();

  Map<String, Object?> toMap() => {
        'id': id,
        'studentId': studentId,
        'courseId': courseId,
        'date': date,
        'markedAt': markedAt,
      };

  factory AttendanceRecord.fromMap(Map<String, Object?> m) => AttendanceRecord(
        id: m['id'] as int?,
        studentId: m['studentId'] as int? ?? 0,
        courseId: m['courseId'] as int? ?? 0,
        date: m['date'] as String? ?? '',
        markedAt: m['markedAt'] as String? ?? '',
      );

  Map<String, Object?> toJson() => toMap();
  factory AttendanceRecord.fromJson(Map<String, Object?> m) => AttendanceRecord.fromMap(m);
}

/// Ledger entry - immutable financial record.
class LedgerEntry {
  int? id;
  final int studentId;
  final String date;
  final String type;
  final String monthLabel;
  final int dueAmount;
  final int paidAmount;
  final int balanceOrCredit; // + = advance, - = baki, 0 = settled
  final String mode;
  final String note;

  LedgerEntry({
    this.id,
    required this.studentId,
    required this.date,
    required this.type,
    this.monthLabel = '',
    required this.dueAmount,
    required this.paidAmount,
    required this.balanceOrCredit,
    this.mode = '',
    this.note = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'studentId': studentId,
        'date': date,
        'type': type,
        'monthLabel': monthLabel,
        'dueAmount': dueAmount,
        'paidAmount': paidAmount,
        'balanceOrCredit': balanceOrCredit,
        'mode': mode,
        'note': note,
      };

  factory LedgerEntry.fromMap(Map<String, Object?> m) => LedgerEntry(
        id: m['id'] as int?,
        studentId: m['studentId'] as int? ?? 0,
        date: m['date'] as String? ?? '',
        type: m['type'] as String? ?? '',
        monthLabel: m['monthLabel'] as String? ?? '',
        dueAmount: m['dueAmount'] as int? ?? 0,
        paidAmount: m['paidAmount'] as int? ?? 0,
        balanceOrCredit: m['balanceOrCredit'] as int? ?? 0,
        mode: m['mode'] as String? ?? '',
        note: m['note'] as String? ?? '',
      );

  Map<String, Object?> toJson() => toMap();
  factory LedgerEntry.fromJson(Map<String, Object?> m) => LedgerEntry.fromMap(m);
}

/// Studio info shown on ID cards / invoices / welcome kit.
class StudioInfo {
  String name;
  String director;
  String contact;
  String socials;
  String address;
  String logoPath;

  StudioInfo({
    this.name = 'Studio Crow',
    this.director = '',
    this.contact = '',
    this.socials = '',
    this.address = '',
    this.logoPath = '',
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'director': director,
        'contact': contact,
        'socials': socials,
        'address': address,
        'logoPath': logoPath,
      };

  factory StudioInfo.fromMap(Map<String, Object?> m) => StudioInfo(
        name: m['name'] as String? ?? 'Studio Crow',
        director: m['director'] as String? ?? '',
        contact: m['contact'] as String? ?? '',
        socials: m['socials'] as String? ?? '',
        address: m['address'] as String? ?? '',
        logoPath: m['logoPath'] as String? ?? '',
      );

  StudioInfo copyWith({String? name, String? director, String? contact, String? socials, String? address, String? logoPath}) =>
      StudioInfo(
        name: name ?? this.name,
        director: director ?? this.director,
        contact: contact ?? this.contact,
        socials: socials ?? this.socials,
        address: address ?? this.address,
        logoPath: logoPath ?? this.logoPath,
      );
}

/// WhatsApp template (editable by owner).
class WaTemplate {
  final String key;
  String text;

  WaTemplate({required this.key, required this.text});

  Map<String, Object?> toMap() => {'key': key, 'text': text};
  factory WaTemplate.fromMap(Map<String, Object?> m) => WaTemplate(
        key: m['key'] as String? ?? '',
        text: m['text'] as String? ?? '',
      );
}

/// Backup metadata stored in settings.
class BackupMeta {
  String? accountEmail;
  String? lastBackupAt;
  String? lastBackupSize;
  bool pending; // true when a backup is queued (e.g. no internet)

  BackupMeta({this.accountEmail, this.lastBackupAt, this.lastBackupSize, this.pending = false});

  Map<String, Object?> toMap() => {
        'accountEmail': accountEmail,
        'lastBackupAt': lastBackupAt,
        'lastBackupSize': lastBackupSize,
        'pending': pending ? 1 : 0,
      };

  factory BackupMeta.fromMap(Map<String, Object?> m) => BackupMeta(
        accountEmail: m['accountEmail'] as String?,
        lastBackupAt: m['lastBackupAt'] as String?,
        lastBackupSize: m['lastBackupSize'] as String?,
        pending: (m['pending'] as int? ?? 0) == 1,
      );
}

/// Computed status snapshot for one student (never stored).
class StudentStatus {
  final MemberStatus status;
  final int cyclePrice;
  final int monthsCovered;
  final DateTime? paidTill; // null when no courses (never expires)
  final int engineDue;
  final int admissionFeeDue;
  final int credit;
  final int daysLeft; // paidTill - today
  final int daysOverdue; // today - paidTill
  final int membershipPaid;

  StudentStatus({
    required this.status,
    required this.cyclePrice,
    required this.monthsCovered,
    required this.paidTill,
    required this.engineDue,
    required this.admissionFeeDue,
    required this.credit,
    required this.daysLeft,
    required this.daysOverdue,
    required this.membershipPaid,
  });

  int get totalDue => engineDue + admissionFeeDue;
}


