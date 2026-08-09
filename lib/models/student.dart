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
  final String? gender;
  final String? religion;
  final String nationality;
  final String? maritalStatus;
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
    this.gender,
    this.religion,
    this.nationality = 'Indian',
    this.maritalStatus,
    this.hobbies = const [],
    this.services = const [],
    this.timingId,
    required this.mobile,
    this.altMobile,
    required this.admissionDate,
    required this.plan,
    this.admissionFeeEnabled = true,
    this.monthsCovered = 0,
    this.cycleBalance = 0,
    this.credit = 0,
    this.admissionFeePaid = false,
    this.lastVisitDate,
    this.isBlocked = false,
    this.ptEnabled = false,
    this.ptSessions = 0,
    this.ptSessionsDone = 0,
    this.ptSessionPrice = 0,
    this.ptPaid = 0,
    this.ptTiming,
    required this.createdAt,
    required this.updatedAt,
  });

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
      dob: map['dob'] != null ? DateTime.parse(map['dob'] as String) : null,
      gender: map['gender'] as String?,
      religion: map['religion'] as String?,
      nationality: map['nationality'] as String? ?? 'Indian',
      maritalStatus: map['maritalStatus'] as String?,
      hobbies: (map['hobbiesJson'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      services: (map['servicesJson'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList(),
      timingId: map['timingId'] as int?,
      mobile: map['mobile'] as String,
      altMobile: map['altMobile'] as String?,
      admissionDate: DateTime.parse(map['admissionDate'] as String),
      plan: map['plan'] as String,
      admissionFeeEnabled: (map['admissionFeeEnabled'] as int? ?? 1) == 1,
      monthsCovered: map['monthsCovered'] as int? ?? 0,
      cycleBalance: (map['cycleBalance'] as num?)?.toDouble() ?? 0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0,
      admissionFeePaid: (map['admissionFeePaid'] as int? ?? 0) == 1,
      lastVisitDate: map['lastVisitDate'] != null
          ? DateTime.parse(map['lastVisitDate'] as String)
          : null,
      isBlocked: (map['isBlocked'] as int? ?? 0) == 1,
      ptEnabled: (map['ptEnabled'] as int? ?? 0) == 1,
      ptSessions: map['ptSessions'] as int? ?? 0,
      ptSessionsDone: map['ptSessionsDone'] as int? ?? 0,
      ptSessionPrice: (map['ptSessionPrice'] as num?)?.toDouble() ?? 0,
      ptPaid: (map['ptPaid'] as num?)?.toDouble() ?? 0,
      ptTiming: map['ptTiming'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
      'hobbiesJson': hobbies.join(','),
      'servicesJson': services.join(','),
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
}