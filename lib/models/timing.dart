class Timing {
  final int? id;
  final String name;
  final String days;
  final String hours;

  const Timing({
    this.id,
    required this.name,
    required this.days,
    required this.hours,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'days': days,
      'hours': hours,
    };
  }

  factory Timing.fromMap(Map<String, dynamic> map) {
    return Timing(
      id: map['id'] as int?,
      name: map['name'] as String,
      days: map['days'] as String,
      hours: map['hours'] as String,
    );
  }

  static List<Timing> get defaults => const [
        Timing(id: 1, name: 'Weekdays Batch', days: 'Mon–Fri', hours: '1 hr'),
        Timing(id: 2, name: 'Weekend Batch', days: 'Sat–Sun', hours: '2 hr'),
      ];
}
