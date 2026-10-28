import 'package:meta/meta.dart';

import '../identifiers.dart';
import '../listing/lesson_duration.dart';
import 'lesson_status.dart';
import 'request_message.dart';

@immutable
final class Lesson {
  Lesson({
    required this.id,
    required this.slotId,
    required this.listingId,
    required this.professorId,
    required this.studentId,
    required DateTime start,
    required this.duration,
    required this.message,
    required DateTime createdAt,
    this.status = const Pending(),
  }) : start = start.toUtc(),
       createdAt = createdAt.toUtc();

  final LessonId id;
  final SlotId slotId;
  final ListingId listingId;
  final UserId professorId;
  final UserId studentId;
  final DateTime start;
  final LessonDuration duration;
  final RequestMessage message;
  final DateTime createdAt;
  final LessonStatus status;

  DateTime get end => start.add(duration.duration);

  Lesson copyWith({LessonStatus? status}) {
    return Lesson(
      id: id,
      slotId: slotId,
      listingId: listingId,
      professorId: professorId,
      studentId: studentId,
      start: start,
      duration: duration,
      message: message,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Lesson &&
      other.id == id &&
      other.slotId == slotId &&
      other.listingId == listingId &&
      other.professorId == professorId &&
      other.studentId == studentId &&
      other.start == start &&
      other.duration == duration &&
      other.message == message &&
      other.createdAt == createdAt &&
      other.status == status;

  @override
  int get hashCode =>
      Object.hash(id, slotId, listingId, professorId, studentId, start, duration, message, createdAt, status);

  @override
  String toString() => 'Lesson($id, ${start.toIso8601String()}, $status)';
}
