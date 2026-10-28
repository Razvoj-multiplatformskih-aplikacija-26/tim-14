import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const halfHour = Duration(minutes: 30);
  final existing = slotAt(lessonStart);

  Result<Slot> add(Slot candidate, {User by = professor, List<Slot>? slots}) =>
      addSlot(candidate, existing: slots ?? [existing], by: by, now: now);

  test('adds a slot that starts when another one ends', () {
    final next = slotAt(existing.end, id: 's-2', listingId: physics);
    expect(add(next), Success(next));
  });

  test('refuses a slot that overlaps one from another listing', () {
    final overlapping = slotAt(lessonStart.add(halfHour), id: 's-2', listingId: physics);
    expect(add(overlapping).errorOrNull, isA<SlotOverlaps>());
  });

  test('refuses a longer slot that covers an existing one', () {
    final covering = slotAt(lessonStart.subtract(halfHour), id: 's-2', duration: LessonDuration.minutes90);
    expect(add(covering).errorOrNull, isA<SlotOverlaps>());
  });

  test("ignores other professors' slots", () {
    final theirs = slotAt(lessonStart, id: 's-9', professorId: otherProfessor.id);
    expect(add(slotAt(lessonStart, id: 's-2'), slots: [theirs]).isSuccess, isTrue);
  });

  test('starts on the hour or half hour', () {
    expect(add(slotAt(lessonStart.add(halfHour)), slots: const []).isSuccess, isTrue);
    expect(
      add(slotAt(lessonStart.add(const Duration(minutes: 15))), slots: const []).errorOrNull,
      isA<SlotNotOnHalfHour>(),
    );
    expect(
      add(slotAt(lessonStart.add(const Duration(seconds: 1))), slots: const []).errorOrNull,
      isA<SlotNotOnHalfHour>(),
    );
  });

  test('refuses a slot that does not start in the future', () {
    expect(add(slotAt(now), slots: const []).errorOrNull, isA<SlotInPast>());
    expect(add(slotAt(now.subtract(const Duration(hours: 1))), slots: const []).errorOrNull, isA<SlotInPast>());
  });

  test("only the slot's professor can add it", () {
    for (final user in [otherProfessor, student, admin]) {
      expect(
        add(
          slotAt(lessonStart, id: 's-2'),
          by: user,
          slots: const [],
        ).errorOrNull,
        isA<NotAllowed>(),
      );
    }
  });
}
