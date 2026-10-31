import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final inTwoDays = now.add(const Duration(days: 2));
  final inOneHour = now.add(const Duration(hours: 1));
  final halfHourAgo = now.subtract(const Duration(minutes: 30));

  group('GetLessonQueue', () {
    test('returns only my lessons, sorted by start', () async {
      final later = lessonAt(now.add(const Duration(days: 5)), id: 'later');
      final sooner = lessonAt(now.add(const Duration(days: 1)), id: 'sooner');
      final notMine = lessonAt(inTwoDays, id: 'not-mine', professorId: const UserId('nikola'));
      final repository = InMemoryLessonRepository([later, notMine, sooner]);

      final lessons = await GetLessonQueue(repository, professor)();

      expect(lessons, [sooner, later]);
    });

    test('a repository error is passed on', () async {
      final repository = InMemoryLessonRepository()..fail = true;

      expect(() => GetLessonQueue(repository, professor)(), throwsA(isA<RepositoryException>()));
    });
  });

  group('ConfirmLesson', () {
    test('confirms the request and rejects the other pending requests for the slot', () async {
      final request = lessonAt(inTwoDays, id: 'ana');
      final competitor = lessonAt(inTwoDays, id: 'marko', studentId: otherStudent.id);
      final otherSlot = lessonAt(inTwoDays, id: 'other-slot', slotId: 's-2', studentId: otherStudent.id);
      final repository = InMemoryLessonRepository([request, competitor, otherSlot]);
      final confirm = ConfirmLesson(repository, FixedClock(now), professor);

      final result = await confirm(request);

      final confirmation = result.valueOrNull!;
      expect(confirmation.confirmed.status, Confirmed(at: now));
      expect(confirmation.rejected, [
        competitor.copyWith(
          status: Rejected(cause: RejectionCause.slotTaken, at: now),
        ),
      ]);
      expect(repository.saveCalls, 2);
      expect(repository.lessons, unorderedEquals([confirmation.confirmed, ...confirmation.rejected, otherSlot]));
    });

    test('a slot already confirmed for another student is taken', () async {
      final request = lessonAt(inTwoDays, id: 'ana');
      final taken = lessonAt(
        inTwoDays,
        id: 'marko',
        studentId: otherStudent.id,
        status: Confirmed(at: now),
      );
      final repository = InMemoryLessonRepository([request, taken]);
      final confirm = ConfirmLesson(repository, FixedClock(now), professor);

      final result = await confirm(request);

      expect(result, const Failure<Confirmation>(SlotTaken()));
      expect(repository.saveCalls, 0);
    });

    test('a student cannot confirm', () async {
      final request = lessonAt(inTwoDays);
      final repository = InMemoryLessonRepository([request]);
      final confirm = ConfirmLesson(repository, FixedClock(now), student);

      final result = await confirm(request);

      expect(result, const Failure<Confirmation>(NotAllowed()));
      expect(repository.saveCalls, 0);
    });
  });

  group('RejectLesson', () {
    test('a pending request is rejected and saved', () async {
      final request = lessonAt(inTwoDays);
      final repository = InMemoryLessonRepository([request]);
      final reject = RejectLesson(repository, FixedClock(now), professor);

      final result = await reject(request);

      expect(result.valueOrNull!.status, Rejected(cause: RejectionCause.byProfessor, at: now));
      expect(repository.saveCalls, 1);
      expect(repository.lessons.single.status, isA<Rejected>());
    });

    test('a confirmed lesson cannot be rejected', () async {
      final lesson = lessonAt(inTwoDays, status: Confirmed(at: now));
      final repository = InMemoryLessonRepository([lesson]);
      final reject = RejectLesson(repository, FixedClock(now), professor);

      final result = await reject(lesson);

      expect(result.errorOrNull, isA<InvalidTransition>());
      expect(repository.saveCalls, 0);
    });
  });

  group('RecordHeld', () {
    final started = lessonAt(halfHourAgo, status: Confirmed(at: now));

    test('a started lesson is marked as held and saved', () async {
      final repository = InMemoryLessonRepository([started]);
      final recordHeld = RecordHeld(repository, FixedClock(now), professor);

      final result = await recordHeld(started);

      expect(result.valueOrNull!.status, Held(at: now));
      expect(repository.saveCalls, 1);
      expect(repository.lessons.single.status, Held(at: now));
    });

    test('the note is kept', () async {
      final note = LessonNote.parse('Uradili smo granične vrednosti.').valueOrNull!;
      final repository = InMemoryLessonRepository([started]);
      final recordHeld = RecordHeld(repository, FixedClock(now), professor);

      final result = await recordHeld(started, note: note);

      expect(result.valueOrNull!.status, Held(at: now, note: note));
    });

    test('a lesson that has not started yet cannot be marked', () async {
      final upcoming = lessonAt(inOneHour, status: Confirmed(at: now));
      final repository = InMemoryLessonRepository([upcoming]);
      final recordHeld = RecordHeld(repository, FixedClock(now), professor);

      final result = await recordHeld(upcoming);

      expect(result, const Failure<Lesson>(LessonNotStarted()));
      expect(repository.saveCalls, 0);
      expect(repository.lessons.single.status, isA<Confirmed>());
    });
  });

  group('RecordNoShow', () {
    test('a started lesson is marked as a no-show and saved', () async {
      final started = lessonAt(halfHourAgo, status: Confirmed(at: now));
      final repository = InMemoryLessonRepository([started]);
      final recordNoShow = RecordNoShow(repository, FixedClock(now), professor);

      final result = await recordNoShow(started);

      expect(result.valueOrNull!.status, NoShow(at: now));
      expect(repository.saveCalls, 1);
    });

    test('a pending request cannot be marked as a no-show', () async {
      final pending = lessonAt(halfHourAgo);
      final repository = InMemoryLessonRepository([pending]);
      final recordNoShow = RecordNoShow(repository, FixedClock(now), professor);

      final result = await recordNoShow(pending);

      expect(result.errorOrNull, isA<InvalidTransition>());
      expect(repository.saveCalls, 0);
    });
  });
}
