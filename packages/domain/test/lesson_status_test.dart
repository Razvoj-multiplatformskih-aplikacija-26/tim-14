import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final statuses = <LessonStatus>[
    const Pending(),
    Confirmed(at: now),
    Rejected(cause: RejectionCause.byProfessor, at: now),
    Cancelled(by: student.id, at: now),
    Held(at: now),
    NoShow(at: now),
  ];
  final allowed = {
    (Pending, Confirmed),
    (Pending, Rejected),
    (Pending, Cancelled),
    (Confirmed, Cancelled),
    (Confirmed, Held),
    (Confirmed, NoShow),
  };

  group('canTransitionTo', () {
    for (final from in statuses) {
      for (final to in statuses) {
        final expected = allowed.contains((from.runtimeType, to.runtimeType));
        test('${from.runtimeType} -> ${to.runtimeType} is ${expected ? 'allowed' : 'refused'}', () {
          expect(from.canTransitionTo(to), expected);
        });
      }
    }
  });

  test('only pending and confirmed lessons are still open', () {
    expect(
      [
        for (final status in statuses)
          if (!status.isFinal) status.runtimeType,
      ],
      [Pending, Confirmed],
    );
  });
}
