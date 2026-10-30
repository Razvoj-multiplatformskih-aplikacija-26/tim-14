import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'helpers.dart';

void main() {
  final at = DateTime.utc(2026, 11, 2, 10);
  final cases = <(LessonStatus, String, BadgeTone)>[
    (const Pending(), 'Na čekanju', BadgeTone.warning),
    (Confirmed(at: at), 'Potvrđeno', BadgeTone.accent),
    (Rejected(cause: RejectionCause.byProfessor, at: at), 'Odbijeno', BadgeTone.destructive),
    (Rejected(cause: RejectionCause.slotTaken, at: at), 'Termin zauzet', BadgeTone.destructive),
    (Cancelled(by: const UserId('u-student'), at: at), 'Otkazano', BadgeTone.neutral),
    (Held(at: at), 'Održano', BadgeTone.neutral),
    (NoShow(at: at), 'Nedolazak', BadgeTone.destructive),
  ];

  for (final (status, label, tone) in cases) {
    testWidgets('$status shows "$label" in ${tone.name}', (tester) async {
      await pumpInApp(tester, LessonStatusBadge(status: status));

      expect(find.text(label), findsOneWidget);
      expect(tester.widget<AppBadge>(find.byType(AppBadge)).tone, tone);
    });
  }
}
