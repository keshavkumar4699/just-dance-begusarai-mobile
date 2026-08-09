class BusinessService {
  final int? id;
  final String name;

  const BusinessService({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory BusinessService.fromMap(Map<String, dynamic> map) {
    return BusinessService(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}
