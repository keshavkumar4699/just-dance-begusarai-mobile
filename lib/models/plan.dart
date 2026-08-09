class Plan {
  final String name;
  final int months;
  final double basePrice;
  final double discount;

  const Plan({
    required this.name,
    required this.months,
    required this.basePrice,
    required this.discount,
  });

  double get finalPrice => basePrice - discount;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'months': months,
      'basePrice': basePrice,
      'discount': discount,
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      name: map['name'] as String,
      months: map['months'] as int,
      basePrice: (map['basePrice'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
    );
  }

  static List<Plan> get defaults => const [
        Plan(name: 'Monthly', months: 1, basePrice: 1000, discount: 0),
        Plan(name: 'Quarterly', months: 3, basePrice: 3000, discount: 500),
        Plan(name: 'Half Yearly', months: 6, basePrice: 6000, discount: 1000),
        Plan(name: 'Yearly', months: 12, basePrice: 12000, discount: 2000),
      ];
}
