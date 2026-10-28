import 'package:meta/meta.dart';

import '../identifiers.dart';
import '../listing/lesson_duration.dart';

@immutable
final class Slot {
  Slot({
    required this.id,
    required this.listingId,
    required this.professorId,
    required DateTime start,
    required this.duration,
  }) : start = start.toUtc();

  final SlotId id;
  final ListingId listingId;
  final UserId professorId;
  final DateTime start;
  final LessonDuration duration;

  DateTime get end => start.add(duration.duration);

  bool overlaps(Slot other) => start.isBefore(other.end) && other.start.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is Slot &&
      other.id == id &&
      other.listingId == listingId &&
      other.professorId == professorId &&
      other.start == start &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(id, listingId, professorId, start, duration);

  @override
  String toString() => 'Slot($id, ${start.toIso8601String()}, ${duration.minutes} min)';
}
