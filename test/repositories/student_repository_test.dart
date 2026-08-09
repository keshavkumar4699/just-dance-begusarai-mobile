import 'package:flutter_test/flutter_test.dart';
import 'package:studio_crow/models/student.dart';
import 'package:studio_crow/core/date/date_formatter.dart';

void main() {
  group('Student Domain & Repository Logic Tests', () {
    test('Category calculation under 12 returns KID\'S', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 10));
      final cat = DateFormatter.calculateCategory(dob, 'Male');
      expect(cat, equals("KID'S"));
    });

    test('Category calculation 12-24 returns BOYS or GIRLS', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 18));
      final catMale = DateFormatter.calculateCategory(dob, 'Male');
      final catFemale = DateFormatter.calculateCategory(dob, 'Female');
      expect(catMale, equals('BOYS'));
      expect(catFemale, equals('GIRLS'));
    });

    test('Category calculation 25+ returns MALE or FEMALE', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 30));
      final catMale = DateFormatter.calculateCategory(dob, 'Male');
      final catFemale = DateFormatter.calculateCategory(dob, 'Female');
      expect(catMale, equals('MALE'));
      expect(catFemale, equals('FEMALE'));
    });

    test('Student model serialization toMap and fromMap works symmetrically', () {
      final student = Student(
        id: 42,
        jdNo: 'JD-042',
        name: 'Amit Sharma',
        category: 'MALE',
        hobbies: ['Gym Fitness', 'Cricket'],
        services: ['Gym Membership'],
        mobile: '9876543210',
        admissionDate: DateTime(2026, 1, 1),
        plan: 'Monthly',
      );

      final map = student.toMap();
      final restored = Student.fromMap(map);

      expect(restored.id, equals(42));
      expect(restored.jdNo, equals('JD-042'));
      expect(restored.name, equals('Amit Sharma'));
      expect(restored.hobbies, contains('Gym Fitness'));
      expect(restored.services, contains('Gym Membership'));
    });
  });
}
