import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final request = lessonAt(lessonStart, id: 'l-1');
  final competitor = lessonAt(lessonStart, id: 'l-2', studentId: otherStudent.id);

  group('confirmLesson', () {
    test('confirms the request and rejects the other pending requests for the slot', () {
      const thirdStudent = UserId('u-student-3');
      final withdrawn = lessonAt(
        lessonStart,
        id: 'l-3',
        studentId: thirdStudent,
        status: Cancelled(by: thirdStudent, at: now),
      );
      final confirmation = confirmLesson(
        request,
        by: professor,
        competing: [request, competitor, withdrawn],
        now: now,
      ).valueOrNull!;
      expect(confirmation.confirmed.status, Confirmed(at: now));
      expect(confirmation.rejected, [
        competitor.copyWith(
          status: Rejected(cause: RejectionCause.slotTaken, at: now),
        ),
      ]);
    });

    test('leaves requests for other slots alone', () {
      final elsewhere = lessonAt(lessonStart, id: 'l-4', slotId: 's-2', studentId: otherStudent.id);
      final confirmation = confirmLesson(request, by: professor, competing: [elsewhere], now: now).valueOrNull!;
      expect(confirmation.rejected, isEmpty);
    });

    test('refuses when the slot is already confirmed for someone else', () {
      final taken = competitor.copyWith(status: Confirmed(at: now));
      expect(confirmLesson(request, by: professor, competing: [taken], now: now).errorOrNull, isA<SlotTaken>());
    });

    test('cannot confirm once the lesson has started', () {
      final result = confirmLesson(request, by: professor, competing: const [], now: lessonStart);
      expect(result.errorOrNull, isA<LessonStarted>());
    });

    test('cannot confirm a withdrawn request', () {
      final withdrawn = request.copyWith(
        status: Cancelled(by: student.id, at: now),
      );
      final result = confirmLesson(withdrawn, by: professor, competing: const [], now: now);
      expect(result.errorOrNull, isA<InvalidTransition>());
    });

    test("only the lesson's professor can confirm", () {
      for (final user in [otherProfessor, student, admin]) {
        expect(confirmLesson(request, by: user, competing: const [], now: now).errorOrNull, isA<NotAllowed>());
      }
    });
  });

  group('rejectLesson', () {
    test('marks the request as rejected by the professor', () {
      final rejected = rejectLesson(request, by: professor, now: now).valueOrNull!;
      expect(rejected.status, Rejected(cause: RejectionCause.byProfessor, at: now));
    });

    test('can still reject a request after its start', () {
      expect(rejectLesson(request, by: professor, now: lessonStart.add(const Duration(hours: 1))).isSuccess, isTrue);
    });

    test('cannot reject a confirmed lesson', () {
      final confirmed = request.copyWith(status: Confirmed(at: now));
      expect(rejectLesson(confirmed, by: professor, now: now).errorOrNull, isA<InvalidTransition>());
    });

    test("only the lesson's professor can reject", () {
      for (final user in [otherProfessor, student, admin]) {
        expect(rejectLesson(request, by: user, now: now).errorOrNull, isA<NotAllowed>());
      }
    });
  });
}
