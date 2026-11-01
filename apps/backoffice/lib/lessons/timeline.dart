import 'package:domain/domain.dart';

typedef TimelineStep = ({String label, DateTime? at, bool done});

// Koraci za „Tok“ u detalju. Status pamti samo vreme svoje promene, pa se pokazuju samo vremena koja domen čuva.
// Održan čas ne zna kad je potvrđen, zato za njega nema koraka „Potvrđeno“.
List<TimelineStep> timelineOf(Lesson lesson) {
  final received = (label: 'Primljeno', at: lesson.createdAt, done: true);
  return switch (lesson.status) {
    Pending() => [
      received,
      (label: 'Čeka potvrdu', at: null, done: false),
      (label: 'Termin', at: lesson.start, done: false),
    ],
    final Confirmed status => [
      received,
      (label: 'Potvrđeno', at: status.at, done: true),
      (label: 'Termin', at: lesson.start, done: false),
    ],
    final Held status => [
      received,
      (label: 'Termin', at: lesson.start, done: true),
      (label: 'Održano', at: status.at, done: true),
    ],
    final NoShow status => [
      received,
      (label: 'Termin', at: lesson.start, done: true),
      (label: 'Nedolazak', at: status.at, done: true),
    ],
    final Rejected status => [
      received,
      (label: status.cause == RejectionCause.slotTaken ? 'Termin zauzet' : 'Odbijeno', at: status.at, done: true),
    ],
    final Cancelled status => [received, (label: 'Otkazano', at: status.at, done: true)],
  };
}
