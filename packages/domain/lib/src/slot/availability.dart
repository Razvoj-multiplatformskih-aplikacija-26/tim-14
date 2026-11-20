import '../identifiers.dart';
import '../lesson/lesson.dart';
import '../lesson/lesson_status.dart';
import '../lesson/transitions.dart';
import 'slot.dart';

// Termin je zauzet kad za njega postoji potvrđen čas. Zahtevi na čekanju ga ne zauzimaju,
// jer više učenika sme da traži isti termin. Isto značenje ima i jedinstveni indeks u bazi.
Set<SlotId> takenSlots(Iterable<Lesson> lessons) => {
  for (final lesson in lessons)
    if (lesson.status is Confirmed) lesson.slotId,
};

// Termini koje učenik još može da zatraži: nisu zauzeti i počinju najranije za requestNotice.
// Dobija samo skup zauzetih termina, ne tuđe časove, pa stranica profesora ne mora da učita tuđe zahteve.
List<Slot> freeSlots(List<Slot> slots, {required Set<SlotId> taken, required DateTime now}) {
  final earliestStart = now.toUtc().add(requestNotice);
  return [
    for (final slot in slots)
      if (!slot.start.isBefore(earliestStart) && !taken.contains(slot.id)) slot,
  ]..sort((a, b) => a.start.compareTo(b.start));
}
