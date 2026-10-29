import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final slot = slotAt(lessonStart);

  Result<Lesson> request({
    User by = student,
    List<Lesson> studentLessons = const [],
    List<Lesson> slotLessons = const [],
    DateTime? at,
  }) => requestLesson(
    id: const LessonId('new'),
    slot: slot,
    by: by,
    message: message,
    studentLessons: studentLessons,
    slotLessons: slotLessons,
    now: at ?? now,
  );

  test('creates a pending lesson for the slot', () {
    final lesson = request().valueOrNull!;
    expect(lesson.status, isA<Pending>());
    expect(lesson.slotId, slot.id);
    expect(lesson.listingId, slot.listingId);
    expect(lesson.professorId, professor.id);
    expect(lesson.studentId, student.id);
    expect(lesson.start, slot.start);
    expect(lesson.end, slot.end);
    expect(lesson.message, message);
    expect(lesson.createdAt, now);
  });

  test('accepts a slot exactly 24 hours ahead', () {
    expect(request(at: lessonStart.subtract(requestNotice)).isSuccess, isTrue);
  });

  test('refuses a slot less than 24 hours ahead', () {
    final at = lessonStart.subtract(requestNotice).add(const Duration(minutes: 1));
    expect(request(at: at).errorOrNull, isA<TooSoonToRequest>());
  });

  group('pending limit', () {
    List<Lesson> pendingAt(DateTime start) => [
      for (var i = 1; i <= maxPendingRequests; i++) lessonAt(start, id: 'p-$i', slotId: 's-other-$i'),
    ];

    test('refuses a fourth pending request', () {
      expect(request(studentLessons: pendingAt(lessonStart)).errorOrNull, isA<TooManyPendingRequests>());
    });

    test('does not count requests whose slot has started', () {
      final started = pendingAt(now.subtract(const Duration(hours: 1)));
      expect(request(studentLessons: started).isSuccess, isTrue);
    });

    test('does not count confirmed lessons', () {
      final confirmed = [for (final lesson in pendingAt(lessonStart)) lesson.copyWith(status: Confirmed(at: now))];
      expect(request(studentLessons: confirmed).isSuccess, isTrue);
    });
  });

  group('slot', () {
    test('refuses a slot already confirmed for another student', () {
      final taken = lessonAt(
        lessonStart,
        studentId: otherStudent.id,
        status: Confirmed(at: now),
      );
      expect(request(slotLessons: [taken]).errorOrNull, isA<SlotTaken>());
    });

    test('accepts a slot that others have only requested', () {
      final competing = lessonAt(lessonStart, studentId: otherStudent.id);
      expect(request(slotLessons: [competing]).isSuccess, isTrue);
    });

    test('refuses a second request for the same slot', () {
      expect(request(slotLessons: [lessonAt(lessonStart)]).errorOrNull, isA<AlreadyRequested>());
    });

    test('accepts a new request after withdrawing the old one', () {
      final withdrawn = lessonAt(
        lessonStart,
        status: Cancelled(by: student.id, at: now),
      );
      expect(request(slotLessons: [withdrawn]).isSuccess, isTrue);
    });
  });

  test('only students can request a lesson', () {
    expect(request(by: professor).errorOrNull, isA<NotAllowed>());
    expect(request(by: admin).errorOrNull, isA<NotAllowed>());
  });
}
