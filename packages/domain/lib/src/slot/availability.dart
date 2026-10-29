import '../lesson/lesson.dart';
import '../lesson/lesson_status.dart';
import '../lesson/transitions.dart';
import 'slot.dart';

List<Slot> freeSlots(List<Slot> slots, {required List<Lesson> lessons, required DateTime now}) {
  final earliestStart = now.toUtc().add(requestNotice);
  final result = <Slot>[];

  for (final slot in slots) {
    if (slot.start.isBefore(earliestStart)) {
      continue;
    }

    final isTaken = lessons.any((lesson) => lesson.slotId == slot.id && lesson.status is Confirmed);
    if (!isTaken) {
      result.add(slot);
    }
  }

  result.sort((a, b) => a.start.compareTo(b.start));
  return result;
}
