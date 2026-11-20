import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final inThreeDays = now.add(const Duration(days: 3));

  // Ime u profilu je namerno drugačije od professor.name: čas mora da prepiše ime iz repozitorijuma profesora.
  final professors = InMemoryProfessorRepository(
    profiles: [ProfessorProfile(id: professor.id, fullName: 'Milica Jovanović', city: City.belgrade, bio: '')],
  );

  test('saves a pending lesson when the rules allow it', () async {
    final repository = InMemoryLessonRepository();
    final requestLesson = RequestLesson(repository, professors, FixedClock(now), student);

    final result = await requestLesson(slot: slotAt(inThreeDays), text: 'Treba mi pomoć oko integrala.');

    expect(result.isSuccess, isTrue);
    final lesson = result.valueOrNull!;
    expect(lesson.status, const Pending());
    expect(lesson.studentId, student.id);
    expect(lesson.slotId, const SlotId('s-1'));
    expect(repository.saveCalls, 1);
    expect(repository.lessons, [lesson]);
  });

  test('the lesson copies the professor name from the profile and the student name from the caller', () async {
    final requestLesson = RequestLesson(InMemoryLessonRepository(), professors, FixedClock(now), student);

    final lesson = (await requestLesson(slot: slotAt(inThreeDays), text: 'Zdravo')).valueOrNull!;

    expect(lesson.professorName, 'Milica Jovanović');
    expect(lesson.studentName, student.name);
  });

  test('an empty message is rejected and nothing is saved', () async {
    final repository = InMemoryLessonRepository();
    final requestLesson = RequestLesson(repository, professors, FixedClock(now), student);

    final result = await requestLesson(slot: slotAt(inThreeDays), text: '   ');

    expect(result, const Failure<Lesson>(InvalidRequestMessage(0, max: RequestMessage.maxLength)));
    expect(repository.saveCalls, 0);
  });

  test('a slot less than 24 hours away is rejected', () async {
    final repository = InMemoryLessonRepository();
    final requestLesson = RequestLesson(repository, professors, FixedClock(now), student);

    final result = await requestLesson(slot: slotAt(now.add(const Duration(hours: 10))), text: 'Zdravo');

    expect(result, const Failure<Lesson>(TooSoonToRequest(notice: requestNotice)));
    expect(repository.saveCalls, 0);
  });

  test('a fourth pending request is rejected', () async {
    final repository = InMemoryLessonRepository([
      lessonAt(inThreeDays, id: 'a', slotId: 's-a'),
      lessonAt(inThreeDays, id: 'b', slotId: 's-b'),
      lessonAt(inThreeDays, id: 'c', slotId: 's-c'),
    ]);
    final requestLesson = RequestLesson(repository, professors, FixedClock(now), student);

    final result = await requestLesson(
      slot: slotAt(inThreeDays, id: 's-d'),
      text: 'Zdravo',
    );

    expect(result, const Failure<Lesson>(TooManyPendingRequests(max: maxPendingRequests)));
    expect(repository.saveCalls, 0);
  });

  test('a slot with a confirmed lesson of another student is taken', () async {
    final repository = InMemoryLessonRepository([
      lessonAt(
        inThreeDays,
        id: 'x',
        studentId: otherStudent.id,
        status: Confirmed(at: now),
      ),
    ]);
    final requestLesson = RequestLesson(repository, professors, FixedClock(now), student);

    final result = await requestLesson(slot: slotAt(inThreeDays), text: 'Zdravo');

    expect(result, const Failure<Lesson>(SlotTaken()));
    expect(repository.saveCalls, 0);
  });

  test('a repository error is passed on', () async {
    final repository = InMemoryLessonRepository()..fail = true;
    final requestLesson = RequestLesson(repository, professors, FixedClock(now), student);

    expect(() => requestLesson(slot: slotAt(inThreeDays), text: 'Zdravo'), throwsA(isA<RepositoryException>()));
  });
}
