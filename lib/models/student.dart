import 'dart:convert';

class Student {
  final int? id;
  final String name;
  final String phone;
  final String parentPhone;
  final List<String> danceStyles;
  final String batchTiming;
  final String joiningDate;
  final double monthlyFee;
  final int dueDay;
  final String status; // 'Active', 'Pending', 'Overdue', 'Inactive'
  final String? photoPath;

  Student({
    this.id,
    required this.name,
    required this.phone,
    this.parentPhone = '',
    required this.danceStyles,
    required this.batchTiming,
    required this.joiningDate,
    required this.monthlyFee,
    this.dueDay = 5,
    this.status = 'Active',
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'parentPhone': parentPhone,
      'danceStyles': jsonEncode(danceStyles),
      'batchTiming': batchTiming,
      'joiningDate': joiningDate,
      'monthlyFee': monthlyFee,
      'dueDay': dueDay,
      'status': status,
      'photoPath': photoPath,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    List<String> parsedStyles = [];
    if (map['danceStyles'] != null) {
      try {
        final decoded = jsonDecode(map['danceStyles']);
        if (decoded is List) {
          parsedStyles = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedStyles = [map['danceStyles'].toString()];
      }
    }

    return Student(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      danceStyles: parsedStyles,
      batchTiming: map['batchTiming'] ?? '',
      joiningDate: map['joiningDate'] ?? '',
      monthlyFee: (map['monthlyFee'] as num?)?.toDouble() ?? 0.0,
      dueDay: (map['dueDay'] as int?) ?? 5,
      status: map['status'] ?? 'Active',
      photoPath: map['photoPath'],
    );
  }

  Student copyWith({
    int? id,
    String? name,
    String? phone,
    String? parentPhone,
    List<String>? danceStyles,
    String? batchTiming,
    String? joiningDate,
    double? monthlyFee,
    int? dueDay,
    String? status,
    String? photoPath,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      danceStyles: danceStyles ?? this.danceStyles,
      batchTiming: batchTiming ?? this.batchTiming,
      joiningDate: joiningDate ?? this.joiningDate,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      dueDay: dueDay ?? this.dueDay,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
