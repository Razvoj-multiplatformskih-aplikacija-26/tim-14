import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const minute = Duration(minutes: 1);
  final pending = lessonAt(lessonStart);
  final confirmed = lessonAt(lessonStart, status: Confirmed(at: now));
  final deadline = cancellationDeadline(confirmed);

  group('withdrawRequest', () {
    test('student withdraws a pending request a minute before the start', () {
      final at = lessonStart.subtract(minute);
      final withdrawn = withdrawRequest(pending, by: student, now: at).valueOrNull!;
      expect(withdrawn.status, Cancelled(by: student.id, at: at));
    });

    test('cannot withdraw once the lesson has started', () {
      expect(withdrawRequest(pending, by: student, now: lessonStart).errorOrNull, isA<LessonStarted>());
    });

    test('cannot withdraw a confirmed lesson', () {
      expect(withdrawRequest(confirmed, by: student, now: now).errorOrNull, isA<InvalidTransition>());
    });

    test('only the student who sent it can withdraw', () {
      for (final user in [otherStudent, professor]) {
        expect(withdrawRequest(pending, by: user, now: now).errorOrNull, isA<NotAllowed>());
      }
    });
  });

  group('cancelLesson', () {
    test('the deadline is 24 hours before the start', () {
      expect(deadline, lessonStart.subtract(const Duration(hours: 24)));
    });

    test('student cancels exactly at the deadline', () {
      final cancelled = cancelLesson(confirmed, by: student, now: deadline).valueOrNull!;
      expect(cancelled.status, Cancelled(by: student.id, at: deadline));
    });

    test('refuses after the deadline', () {
      expect(cancelLesson(confirmed, by: student, now: deadline.add(minute)).errorOrNull, isA<CancellationTooLate>());
    });

    test('professor follows the same deadline', () {
      expect(
        cancelLesson(confirmed, by: professor, now: deadline).valueOrNull!.status,
        Cancelled(by: professor.id, at: deadline),
      );
      expect(cancelLesson(confirmed, by: professor, now: deadline.add(minute)).errorOrNull, isA<CancellationTooLate>());
    });

    test('a pending request is withdrawn, not cancelled', () {
      expect(cancelLesson(pending, by: student, now: now).errorOrNull, isA<InvalidTransition>());
    });

    test('nobody outside the lesson can cancel it', () {
      for (final user in [otherStudent, otherProfessor, admin]) {
        expect(cancelLesson(confirmed, by: user, now: now).errorOrNull, isA<NotAllowed>());
      }
    });
  });
}
