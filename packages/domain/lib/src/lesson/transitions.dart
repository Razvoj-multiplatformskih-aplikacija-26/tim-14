import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../access_policy.dart';
import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import '../slot/slot.dart';
import '../user.dart';
import 'lesson.dart';
import 'lesson_note.dart';
import 'lesson_status.dart';
import 'request_message.dart';

const requestNotice = Duration(hours: 24);
const cancellationNotice = Duration(hours: 24);
const maxPendingRequests = 3;

bool hasStarted(Lesson lesson, {required DateTime now}) => !now.toUtc().isBefore(lesson.start);

DateTime cancellationDeadline(Lesson lesson) => lesson.start.subtract(cancellationNotice);

bool mayStillCancel(Lesson lesson, {required DateTime now}) => !now.toUtc().isAfter(cancellationDeadline(lesson));

bool isWaiting(Lesson lesson, {required DateTime now}) => lesson.status is Pending && !hasStarted(lesson, now: now);

Result<Lesson> requestLesson({
  required LessonId id,
  required Slot slot,
  required User by,
  required RequestMessage message,
  required List<Lesson> studentLessons,
  required List<Lesson> slotLessons,
  required DateTime now,
}) {
  if (!AccessPolicy.canRequestLesson(by)) return const Failure(NotAllowed());
  final instant = now.toUtc();
  if (slot.start.isBefore(instant.add(requestNotice))) return const Failure(TooSoonToRequest());
  final forSlot = slotLessons.where((lesson) => lesson.slotId == slot.id);
  if (forSlot.any((lesson) => lesson.studentId == by.id && !lesson.status.isFinal)) {
    return const Failure(AlreadyRequested());
  }
  if (forSlot.any((lesson) => lesson.status is Confirmed)) return const Failure(SlotTaken());
  final waiting = studentLessons.where((lesson) => lesson.studentId == by.id && isWaiting(lesson, now: instant));
  if (waiting.length >= maxPendingRequests) return const Failure(TooManyPendingRequests());
  return Success(
    Lesson(
      id: id,
      slotId: slot.id,
      listingId: slot.listingId,
      professorId: slot.professorId,
      studentId: by.id,
      start: slot.start,
      duration: slot.duration,
      message: message,
      createdAt: instant,
    ),
  );
}

Result<Lesson> withdrawRequest(Lesson lesson, {required User by, required DateTime now}) {
  if (!AccessPolicy.canWithdraw(by, lesson)) return const Failure(NotAllowed());
  final next = Cancelled(by: by.id, at: now.toUtc());
  if (lesson.status is! Pending) return Failure(InvalidTransition(from: lesson.status, to: next));
  if (hasStarted(lesson, now: now)) return const Failure(LessonStarted());
  return Success(lesson.copyWith(status: next));
}

@immutable
final class Confirmation {
  const Confirmation({required this.confirmed, required this.rejected});

  final Lesson confirmed;
  final List<Lesson> rejected;

  @override
  bool operator ==(Object other) =>
      other is Confirmation &&
      other.confirmed == confirmed &&
      const ListEquality<Lesson>().equals(other.rejected, rejected);

  @override
  int get hashCode => Object.hash(confirmed, const ListEquality<Lesson>().hash(rejected));

  @override
  String toString() => 'Confirmation(${confirmed.id}, rejected ${rejected.length})';
}

Result<Confirmation> confirmLesson(
  Lesson lesson, {
  required User by,
  required List<Lesson> competing,
  required DateTime now,
}) {
  if (!AccessPolicy.canDecide(by, lesson)) return const Failure(NotAllowed());
  final at = now.toUtc();
  final next = Confirmed(at: at);
  if (!lesson.status.canTransitionTo(next)) return Failure(InvalidTransition(from: lesson.status, to: next));
  if (hasStarted(lesson, now: at)) return const Failure(LessonStarted());
  final others = competing.where((other) => other.slotId == lesson.slotId && other.id != lesson.id);
  if (others.any((other) => other.status is Confirmed)) return const Failure(SlotTaken());
  return Success(
    Confirmation(
      confirmed: lesson.copyWith(status: next),
      rejected: [
        for (final other in others)
          if (other.status is Pending)
            other.copyWith(
              status: Rejected(cause: RejectionCause.slotTaken, at: at),
            ),
      ],
    ),
  );
}

Result<Lesson> rejectLesson(Lesson lesson, {required User by, required DateTime now}) {
  if (!AccessPolicy.canDecide(by, lesson)) return const Failure(NotAllowed());
  final next = Rejected(cause: RejectionCause.byProfessor, at: now.toUtc());
  if (!lesson.status.canTransitionTo(next)) return Failure(InvalidTransition(from: lesson.status, to: next));
  return Success(lesson.copyWith(status: next));
}

Result<Lesson> cancelLesson(Lesson lesson, {required User by, required DateTime now}) {
  if (!AccessPolicy.canCancel(by, lesson)) return const Failure(NotAllowed());
  final next = Cancelled(by: by.id, at: now.toUtc());
  if (lesson.status is! Confirmed) return Failure(InvalidTransition(from: lesson.status, to: next));
  if (!mayStillCancel(lesson, now: now)) return const Failure(CancellationTooLate());
  return Success(lesson.copyWith(status: next));
}

Result<Lesson> recordHeld(Lesson lesson, {required User by, required DateTime now, LessonNote? note}) => _recordOutcome(
  lesson,
  by: by,
  now: now,
  next: Held(at: now.toUtc(), note: note),
);

Result<Lesson> recordNoShow(Lesson lesson, {required User by, required DateTime now}) => _recordOutcome(
  lesson,
  by: by,
  now: now,
  next: NoShow(at: now.toUtc()),
);

Result<Lesson> _recordOutcome(Lesson lesson, {required User by, required DateTime now, required LessonStatus next}) {
  if (!AccessPolicy.canRecordOutcome(by, lesson)) return const Failure(NotAllowed());
  if (!lesson.status.canTransitionTo(next)) return Failure(InvalidTransition(from: lesson.status, to: next));
  if (!hasStarted(lesson, now: now)) return const Failure(LessonNotStarted());
  return Success(lesson.copyWith(status: next));
}
