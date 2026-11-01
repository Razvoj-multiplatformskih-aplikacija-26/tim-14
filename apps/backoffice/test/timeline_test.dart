import 'package:backoffice/lessons/timeline.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 1, 10);
  final start = DateTime.utc(2026, 11, 5, 16);
  final changedAt = DateTime.utc(2026, 11, 2, 12);

  Lesson lesson(LessonStatus status) => Lesson(
    id: const LessonId('c-1'),
    slotId: const SlotId('s-1'),
    listingId: const ListingId('l-1'),
    professorId: const UserId('milica'),
    studentId: const UserId('ana'),
    start: start,
    duration: LessonDuration.minutes60,
    message: RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!,
    createdAt: createdAt,
    status: status,
  );

  List<String> labels(List<TimelineStep> steps) => [for (final step in steps) step.label];

  test('a pending request waits for the decision and has no time for it', () {
    final steps = timelineOf(lesson(const Pending()));

    expect(labels(steps), ['Primljeno', 'Čeka potvrdu', 'Termin']);
    expect(steps[0].at, createdAt);
    expect(steps[1].at, isNull);
    expect(steps[1].done, isFalse);
    expect(steps[2].at, start);
  });

  test('a confirmed lesson shows when it was confirmed and the upcoming start', () {
    final steps = timelineOf(lesson(Confirmed(at: changedAt)));

    expect(labels(steps), ['Primljeno', 'Potvrđeno', 'Termin']);
    expect(steps[1].at, changedAt);
    expect(steps[2].done, isFalse);
  });

  test('held and no-show lessons end with the outcome after the start', () {
    final held = timelineOf(lesson(Held(at: changedAt)));
    final noShow = timelineOf(lesson(NoShow(at: changedAt)));

    expect(labels(held), ['Primljeno', 'Termin', 'Održano']);
    expect(labels(noShow), ['Primljeno', 'Termin', 'Nedolazak']);
    expect(held.every((step) => step.done), isTrue);
  });

  test('a rejection says whether the professor rejected it or the slot was taken', () {
    final byProfessor = timelineOf(lesson(Rejected(cause: RejectionCause.byProfessor, at: changedAt)));
    final slotTaken = timelineOf(lesson(Rejected(cause: RejectionCause.slotTaken, at: changedAt)));

    expect(labels(byProfessor), ['Primljeno', 'Odbijeno']);
    expect(labels(slotTaken), ['Primljeno', 'Termin zauzet']);
  });

  test('a cancelled lesson ends with the cancellation', () {
    final steps = timelineOf(lesson(Cancelled(by: const UserId('ana'), at: changedAt)));

    expect(labels(steps), ['Primljeno', 'Otkazano']);
    expect(steps[1].at, changedAt);
  });
}
