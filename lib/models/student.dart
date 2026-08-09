import 'dart:convert';

enum MemberStatus {
  active,
  nearExpiry,
  expired,
  inactive,
  blocked,
}

class Student {
  final int? id;
  final String jdNo;
  final String name;
  final String? fatherName;
  final String? motherName;
  final String? photoPath;
  final String? permVillage;
  final String? permPO;
  final String? permDist;
  final String? permPin;
  final bool corrSame;
  final String? corrVillage;
  final String? corrPO;
  final String? corrDist;
  final String? corrPin;
  final String? aadhar;
  final DateTime? dob;
  final String gender;
  final String category;
  final String religion;
  final String nationality;
  final String maritalStatus;
  final List<String> hobbies;
  final List<String> services;
  final int? timingId;
  final String mobile;
  final String? altMobile;
  final DateTime admissionDate;
  final String plan;
  final bool admissionFeeEnabled;
  final int monthsCovered;
  final double cycleBalance;
  final double credit;
  final bool admissionFeePaid;
  final DateTime? lastVisitDate;
  final bool isBlocked;
  final bool ptEnabled;
  final int ptSessions;
  final int ptSessionsDone;
  final double ptSessionPrice;
  final double ptPaid;
  final String? ptTiming;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    this.id,
    required this.jdNo,
    required this.name,
    this.fatherName,
    this.motherName,
    this.photoPath,
    this.permVillage,
    this.permPO,
    this.permDist,
    this.permPin,
    this.corrSame = true,
    this.corrVillage,
    this.corrPO,
    this.corrDist,
    this.corrPin,
    this.aadhar,
    this.dob,
    this.gender = 'Male',
    required this.category,
    this.religion = 'Hindu',
    this.nationality = 'Indian',
    this.maritalStatus = 'Unmarried',
    required this.hobbies,
    required this.services,
    this.timingId,
    required this.mobile,
    this.altMobile,
    required this.admissionDate,
    required this.plan,
    this.admissionFeeEnabled = true,
    this.monthsCovered = 0,
    this.cycleBalance = 0.0,
    this.credit = 0.0,
    this.admissionFeePaid = false,
    this.lastVisitDate,
    this.isBlocked = false,
    this.ptEnabled = false,
    this.ptSessions = 0,
    this.ptSessionsDone = 0,
    this.ptSessionPrice = 0.0,
    this.ptPaid = 0.0,
    this.ptTiming,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Student copyWith({
    int? id,
    String? jdNo,
    String? name,
    String? fatherName,
    String? motherName,
    String? photoPath,
    String? permVillage,
    String? permPO,
    String? permDist,
    String? permPin,
    bool? corrSame,
    String? corrVillage,
    String? corrPO,
    String? corrDist,
    String? corrPin,
    String? aadhar,
    DateTime? dob,
    String? gender,
    String? category,
    String? religion,
    String? nationality,
    String? maritalStatus,
    List<String>? hobbies,
    List<String>? services,
    int? timingId,
    String? mobile,
    String? altMobile,
    DateTime? admissionDate,
    String? plan,
    bool? admissionFeeEnabled,
    int? monthsCovered,
    double? cycleBalance,
    double? credit,
    bool? admissionFeePaid,
    DateTime? lastVisitDate,
    bool? isBlocked,
    bool? ptEnabled,
    int? ptSessions,
    int? ptSessionsDone,
    double? ptSessionPrice,
    double? ptPaid,
    String? ptTiming,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      jdNo: jdNo ?? this.jdNo,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      photoPath: photoPath ?? this.photoPath,
      permVillage: permVillage ?? this.permVillage,
      permPO: permPO ?? this.permPO,
      permDist: permDist ?? this.permDist,
      permPin: permPin ?? this.permPin,
      corrSame: corrSame ?? this.corrSame,
      corrVillage: corrVillage ?? this.corrVillage,
      corrPO: corrPO ?? this.corrPO,
      corrDist: corrDist ?? this.corrDist,
      corrPin: corrPin ?? this.corrPin,
      aadhar: aadhar ?? this.aadhar,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      religion: religion ?? this.religion,
      nationality: nationality ?? this.nationality,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      hobbies: hobbies ?? this.hobbies,
      services: services ?? this.services,
      timingId: timingId ?? this.timingId,
      mobile: mobile ?? this.mobile,
      altMobile: altMobile ?? this.altMobile,
      admissionDate: admissionDate ?? this.admissionDate,
      plan: plan ?? this.plan,
      admissionFeeEnabled: admissionFeeEnabled ?? this.admissionFeeEnabled,
      monthsCovered: monthsCovered ?? this.monthsCovered,
      cycleBalance: cycleBalance ?? this.cycleBalance,
      credit: credit ?? this.credit,
      admissionFeePaid: admissionFeePaid ?? this.admissionFeePaid,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      isBlocked: isBlocked ?? this.isBlocked,
      ptEnabled: ptEnabled ?? this.ptEnabled,
      ptSessions: ptSessions ?? this.ptSessions,
      ptSessionsDone: ptSessionsDone ?? this.ptSessionsDone,
      ptSessionPrice: ptSessionPrice ?? this.ptSessionPrice,
      ptPaid: ptPaid ?? this.ptPaid,
      ptTiming: ptTiming ?? this.ptTiming,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'category': category,
      'religion': religion,
      'nationality': nationality,
      'maritalStatus': maritalStatus,
      'hobbiesJSON': jsonEncode(hobbies),
      'servicesJSON': jsonEncode(services),
      'timingId': timingId,
      'mobile': mobile,
      'altMobile': altMobile,
      'admissionDate': admissionDate.toIso8601String(),
      'plan': plan,
      'admissionFeeEnabled': admissionFeeEnabled ? 1 : 0,
      'monthsCovered': monthsCovered,
      'cycleBalance': cycleBalance,
      'credit': credit,
      'admissionFeePaid': admissionFeePaid ? 1 : 0,
      'lastVisitDate': lastVisitDate?.toIso8601String(),
      'isBlocked': isBlocked ? 1 : 0,
      'ptEnabled': ptEnabled ? 1 : 0,
      'ptSessions': ptSessions,
      'ptSessionsDone': ptSessionsDone,
      'ptSessionPrice': ptSessionPrice,
      'ptPaid': ptPaid,
      'ptTiming': ptTiming,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      jdNo: map['jdNo'] as String,
      name: map['name'] as String,
      fatherName: map['fatherName'] as String?,
      motherName: map['motherName'] as String?,
      photoPath: map['photoPath'] as String?,
      permVillage: map['permVillage'] as String?,
      permPO: map['permPO'] as String?,
      permDist: map['permDist'] as String?,
      permPin: map['permPin'] as String?,
      corrSame: (map['corrSame'] as int? ?? 1) == 1,
      corrVillage: map['corrVillage'] as String?,
      corrPO: map['corrPO'] as String?,
      corrDist: map['corrDist'] as String?,
      corrPin: map['corrPin'] as String?,
      aadhar: map['aadhar'] as String?,
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'] as String) : null,
      gender: map['gender'] as String? ?? 'Male',
      category: map['category'] as String? ?? 'MALE',
      religion: map['religion'] as String? ?? 'Hindu',
      nationality: map['nationality'] as String? ?? 'Indian',
      maritalStatus: map['maritalStatus'] as String? ?? 'Unmarried',
      hobbies: (jsonDecode(map['hobbiesJSON'] as String? ?? '[]') as List).cast<String>(),
      services: (jsonDecode(map['servicesJSON'] as String? ?? '[]') as List).cast<String>(),
      timingId: map['timingId'] as int?,
      mobile: map['mobile'] as String,
      altMobile: map['altMobile'] as String?,
      admissionDate: DateTime.parse(map['admissionDate'] as String),
      plan: map['plan'] as String? ?? 'Monthly',
      admissionFeeEnabled: (map['admissionFeeEnabled'] as int? ?? 1) == 1,
      monthsCovered: map['monthsCovered'] as int? ?? 0,
      cycleBalance: (map['cycleBalance'] as num? ?? 0).toDouble(),
      credit: (map['credit'] as num? ?? 0).toDouble(),
      admissionFeePaid: (map['admissionFeePaid'] as int? ?? 0) == 1,
      lastVisitDate: map['lastVisitDate'] != null ? DateTime.tryParse(map['lastVisitDate'] as String) : null,
      isBlocked: (map['isBlocked'] as int? ?? 0) == 1,
      ptEnabled: (map['ptEnabled'] as int? ?? 0) == 1,
      ptSessions: map['ptSessions'] as int? ?? 0,
      ptSessionsDone: map['ptSessionsDone'] as int? ?? 0,
      ptSessionPrice: (map['ptSessionPrice'] as num? ?? 0).toDouble(),
      ptPaid: (map['ptPaid'] as num? ?? 0).toDouble(),
      ptTiming: map['ptTiming'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }
}
