import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final confirmed = lessonAt(lessonStart, status: Confirmed(at: now));
  final afterStart = lessonStart.add(const Duration(minutes: 50));
  final note = LessonNote.parse('Uradili smo granične vrednosti.').valueOrNull!;

  test('records a held lesson with a note', () {
    final held = recordHeld(confirmed, by: professor, now: afterStart, note: note).valueOrNull!;
    expect(held.status, Held(at: afterStart, note: note));
  });

  test('records a held lesson without a note', () {
    expect(recordHeld(confirmed, by: professor, now: afterStart).valueOrNull!.status, Held(at: afterStart));
  });

  test('records a no-show', () {
    expect(recordNoShow(confirmed, by: professor, now: afterStart).valueOrNull!.status, NoShow(at: afterStart));
  });

  test('the outcome can be recorded from the moment the lesson starts', () {
    expect(recordHeld(confirmed, by: professor, now: lessonStart).isSuccess, isTrue);
    expect(recordNoShow(confirmed, by: professor, now: lessonStart).isSuccess, isTrue);
  });

  test('cannot record an outcome before the start', () {
    final early = lessonStart.subtract(const Duration(minutes: 1));
    expect(recordHeld(confirmed, by: professor, now: early).errorOrNull, isA<LessonNotStarted>());
    expect(recordNoShow(confirmed, by: professor, now: early).errorOrNull, isA<LessonNotStarted>());
  });

  test('needs a confirmed lesson', () {
    final pending = lessonAt(lessonStart);
    final held = confirmed.copyWith(status: Held(at: afterStart));
    expect(recordHeld(pending, by: professor, now: afterStart).errorOrNull, isA<InvalidTransition>());
    expect(recordNoShow(held, by: professor, now: afterStart).errorOrNull, isA<InvalidTransition>());
  });

  test("only the lesson's professor records the outcome", () {
    for (final user in [student, otherProfessor, admin]) {
      expect(recordHeld(confirmed, by: user, now: afterStart).errorOrNull, isA<NotAllowed>());
      expect(recordNoShow(confirmed, by: user, now: afterStart).errorOrNull, isA<NotAllowed>());
    }
  });
}
