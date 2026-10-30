import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final inTwoDays = now.add(const Duration(days: 2));
  final inTenHours = now.add(const Duration(hours: 10));

  group('WithdrawRequest', () {
    test('a pending request is withdrawn and saved', () async {
      final lesson = lessonAt(inTwoDays);
      final repository = InMemoryLessonRepository([lesson]);
      final withdraw = WithdrawRequest(repository, FixedClock(now), student);

      final result = await withdraw(lesson);

      expect(result.valueOrNull!.status, Cancelled(by: student.id, at: now));
      expect(repository.saveCalls, 1);
      expect(repository.lessons.single.status, isA<Cancelled>());
    });

    test('a confirmed lesson cannot be withdrawn', () async {
      final lesson = lessonAt(inTwoDays, status: Confirmed(at: now));
      final repository = InMemoryLessonRepository([lesson]);
      final withdraw = WithdrawRequest(repository, FixedClock(now), student);

      final result = await withdraw(lesson);

      expect(result.errorOrNull, isA<InvalidTransition>());
      expect(repository.saveCalls, 0);
    });

    test('another student cannot withdraw it', () async {
      final lesson = lessonAt(inTwoDays);
      final repository = InMemoryLessonRepository([lesson]);
      final withdraw = WithdrawRequest(repository, FixedClock(now), otherStudent);

      final result = await withdraw(lesson);

      expect(result, const Failure<Lesson>(NotAllowed()));
      expect(repository.saveCalls, 0);
    });
  });

  group('CancelLesson', () {
    test('a confirmed lesson in two days is cancelled and saved', () async {
      final lesson = lessonAt(inTwoDays, status: Confirmed(at: now));
      final repository = InMemoryLessonRepository([lesson]);
      final cancel = CancelLesson(repository, FixedClock(now), student);

      final result = await cancel(lesson);

      expect(result.valueOrNull!.status, Cancelled(by: student.id, at: now));
      expect(repository.saveCalls, 1);
    });

    test('a confirmed lesson in ten hours is too late to cancel', () async {
      final lesson = lessonAt(inTenHours, status: Confirmed(at: now));
      final repository = InMemoryLessonRepository([lesson]);
      final cancel = CancelLesson(repository, FixedClock(now), student);

      final result = await cancel(lesson);

      expect(result, const Failure<Lesson>(CancellationTooLate()));
      expect(repository.saveCalls, 0);
      expect(repository.lessons.single.status, isA<Confirmed>());
    });

    test('a pending lesson is withdrawn, not cancelled', () async {
      final lesson = lessonAt(inTwoDays);
      final repository = InMemoryLessonRepository([lesson]);
      final cancel = CancelLesson(repository, FixedClock(now), student);

      final result = await cancel(lesson);

      expect(result.errorOrNull, isA<InvalidTransition>());
      expect(repository.saveCalls, 0);
    });
  });
}
