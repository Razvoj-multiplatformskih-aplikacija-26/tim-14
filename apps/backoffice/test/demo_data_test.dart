import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  group('nextThursdayAt17', () {
    test('picks this Thursday when it is at least 2 days away', () {
      expect(nextThursdayAt17(DateTime(2026, 11, 2, 10)), DateTime(2026, 11, 5, 17));
    });

    test('skips a Thursday that is less than 2 days away', () {
      expect(nextThursdayAt17(DateTime(2026, 11, 4, 18)), DateTime(2026, 11, 12, 17));
      expect(nextThursdayAt17(DateTime(2026, 11, 5, 10)), DateTime(2026, 11, 12, 17));
    });
  });

  group('demo lessons', () {
    late List<Lesson> lessons;
    late FakeLessonRepository repository;

    setUp(() {
      lessons = demoLessons(DateTime.now());
      repository = FakeLessonRepository(lessons, FailSwitch(), delay: Duration.zero);
    });

    Lesson byId(String id) => lessons.firstWhere((lesson) => lesson.id == LessonId(id));

    test('every lesson has a student name and a listing title', () {
      for (final lesson in lessons) {
        expect(studentNames[lesson.studentId], isNotNull, reason: '${lesson.id}');
        expect(listingTitles[lesson.listingId], isNotNull, reason: '${lesson.id}');
      }
    });

    test('every request was sent at least 24 hours before the start', () {
      for (final lesson in lessons) {
        expect(lesson.start.difference(lesson.createdAt), greaterThanOrEqualTo(requestNotice), reason: '${lesson.id}');
      }
    });

    test('confirming one Thursday request rejects the other two', () async {
      final result = await ConfirmLesson(repository, const SystemClock(), milica)(byId('c-01'));

      final confirmation = (result as Success<Confirmation>).value;
      expect(confirmation.rejected.map((lesson) => lesson.id), unorderedEquals([LessonId('c-02'), LessonId('c-03')]));
      for (final lesson in confirmation.rejected) {
        expect((lesson.status as Rejected).cause, RejectionCause.slotTaken);
      }
    });

    test('the lesson that started an hour ago can be marked as held', () async {
      final result = await RecordHeld(repository, const SystemClock(), milica)(byId('c-06'));

      expect(result, isA<Success<Lesson>>());
    });

    test('a future confirmed lesson cannot be marked as held yet', () async {
      final result = await RecordHeld(repository, const SystemClock(), milica)(byId('c-07'));

      expect(result.errorOrNull, isA<LessonNotStarted>());
    });
  });

  test('the verification queue shows the 4 awaiting professors, oldest first', () async {
    final repository = FakeVerificationRepository(demoProfessors(DateTime.now()), FailSwitch(), delay: Duration.zero);

    final queue = await GetVerificationQueue(repository)();

    expect(queue.map((profile) => profile.fullName), [
      'Dragan Simić',
      'Ana Kovačević',
      'Milan Đurić',
      'Jelena Marković',
    ]);
  });

  test('Simuliraj grešku fails only the next call', () async {
    final failSwitch = FailSwitch();
    final repository = FakeLessonRepository(demoLessons(DateTime.now()), failSwitch, delay: Duration.zero);
    failSwitch.failNext = true;

    await expectLater(repository.lessonsOfProfessor(milica.id), throwsA(isA<RepositoryException>()));
    expect(failSwitch.failNext, isFalse);
    expect(await repository.lessonsOfProfessor(milica.id), hasLength(15));
  });
}
