import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final slot = slotAt(lessonStart);
  final other = slotAt(lessonStart.add(const Duration(hours: 2)), id: 's-2');

  List<Slot> free(List<Slot> slots, [List<Lesson> lessons = const []]) => freeSlots(slots, lessons: lessons, now: now);

  Lesson lessonFor(Slot slot, LessonStatus status, {String id = 'lesson-1', UserId? studentId}) =>
      lessonAt(slot.start, id: id, slotId: slot.id.value, studentId: studentId, status: status);

  test('returns every upcoming slot when there are no lessons', () {
    expect(free([slot, other]), [slot, other]);
  });

  test('returns nothing when the professor offers no slots', () {
    expect(free(const []), isEmpty);
  });

  test('a confirmed lesson takes its slot', () {
    expect(free([slot, other], [lessonFor(slot, Confirmed(at: now))]), [other]);
  });

  test('pending requests do not take a slot, since several students may ask for it', () {
    final lessons = [
      lessonFor(slot, const Pending()),
      lessonFor(slot, const Pending(), id: 'lesson-2', studentId: otherStudent.id),
    ];
    expect(free([slot], lessons), [slot]);
  });

  test('cancelled and rejected lessons free the slot again', () {
    final lessons = [
      lessonFor(slot, Cancelled(by: student.id, at: now)),
      lessonFor(
        other,
        Rejected(cause: RejectionCause.byProfessor, at: now),
        id: 'lesson-2',
      ),
    ];
    expect(free([slot, other], lessons), [slot, other]);
  });

  test('a confirmed lesson only takes its own slot', () {
    expect(free([other], [lessonFor(slot, Confirmed(at: now))]), [other]);
  });

  test('hides slots that start sooner than requestNotice, but keeps one exactly at the edge', () {
    final soon = slotAt(now.add(requestNotice).subtract(const Duration(hours: 1)));
    final exactly = slotAt(now.add(requestNotice), id: 's-2');
    final later = slotAt(now.add(requestNotice).add(const Duration(hours: 1)), id: 's-3');
    expect(free([soon, exactly, later]), [exactly, later]);
  });

  test('hides slots in the past', () {
    expect(free([slotAt(now.subtract(const Duration(days: 1)))]), isEmpty);
  });

  test('sorts slots by start', () {
    final first = slotAt(lessonStart, id: 's-1');
    final second = slotAt(lessonStart.add(const Duration(days: 1)), id: 's-2');
    final third = slotAt(lessonStart.add(const Duration(days: 2)), id: 's-3');
    expect(free([third, first, second]), [first, second, third]);
  });

  test('a slot is free exactly when requestLesson accepts it', () {
    final slots = [
      slotAt(now.subtract(const Duration(hours: 1)), id: 's-past'),
      slotAt(now.add(const Duration(hours: 23)), id: 's-soon'),
      slotAt(now.add(requestNotice), id: 's-edge'),
      slotAt(lessonStart, id: 's-taken'),
      slotAt(lessonStart.add(const Duration(hours: 2)), id: 's-requested'),
      slotAt(lessonStart.add(const Duration(hours: 4)), id: 's-open'),
    ];
    final lessons = [
      lessonFor(
        slots[3],
        Confirmed(at: now),
        id: 'lesson-taken',
        studentId: otherStudent.id,
      ),
      lessonFor(slots[4], const Pending(), id: 'lesson-requested', studentId: otherStudent.id),
    ];
    final offered = free(slots, lessons);

    for (final candidate in slots) {
      final result = requestLesson(
        id: const LessonId('new'),
        slot: candidate,
        by: student,
        message: message,
        studentLessons: const [],
        slotLessons: lessons,
        now: now,
      );
      expect(offered.contains(candidate), result.isSuccess, reason: '${candidate.id} → $result');
    }
  });
}
