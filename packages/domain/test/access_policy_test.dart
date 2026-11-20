import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('canView', () {
    final lesson = lessonAt(lessonStart);

    test('the lesson is visible to its own student and its own professor', () {
      expect(AccessPolicy.canView(student, lesson), isTrue);
      expect(AccessPolicy.canView(professor, lesson), isTrue);
    });

    test('another student, another professor and the admin do not see it', () {
      expect(AccessPolicy.canView(otherStudent, lesson), isFalse);
      expect(AccessPolicy.canView(otherProfessor, lesson), isFalse);
      expect(AccessPolicy.canView(admin, lesson), isFalse);
    });

    test('the same id with a different role does not count', () {
      final sameIdAsStudent = User(id: student.id, name: student.name, role: Role.professor);
      expect(AccessPolicy.canView(sameIdAsStudent, lesson), isFalse);
    });
  });

  test('only the admin sees the verification details, a visitor does not', () {
    expect(AccessPolicy.canSeeVerificationDetails(admin), isTrue);
    expect(AccessPolicy.canSeeVerificationDetails(professor), isFalse);
    expect(AccessPolicy.canSeeVerificationDetails(student), isFalse);
    expect(AccessPolicy.canSeeVerificationDetails(null), isFalse);
  });

  test('the mobile app is for students, the backoffice for professors and admins', () {
    expect(AccessPolicy.canUseMobileApp(student), isTrue);
    expect(AccessPolicy.canUseMobileApp(professor), isFalse);
    expect(AccessPolicy.canUseMobileApp(admin), isFalse);

    expect(AccessPolicy.canUseBackoffice(student), isFalse);
    expect(AccessPolicy.canUseBackoffice(professor), isTrue);
    expect(AccessPolicy.canUseBackoffice(admin), isTrue);
  });
}
