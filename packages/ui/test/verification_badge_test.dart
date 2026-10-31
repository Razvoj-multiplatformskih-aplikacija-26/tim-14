import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'helpers.dart';

void main() {
  final at = DateTime.utc(2026, 11, 2, 10);
  const admin = UserId('u-admin');
  final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jelena').valueOrNull!;
  final reason = RejectionReason.parse('Fotografija je mutna.').valueOrNull!;
  final cases = <(VerificationStatus, String, BadgeTone)>[
    (const NotVerified(), 'Nepotvrđeno', BadgeTone.neutral),
    (AwaitingReview(submittedAt: at, diplomaFile: 'diploma.pdf', linkedIn: linkedIn), 'Na proveri', BadgeTone.warning),
    (Verified(by: admin, at: at), 'Potvrđeno', BadgeTone.verified),
    (VerificationRejected(by: admin, at: at, reason: reason), 'Odbijeno', BadgeTone.destructive),
  ];

  for (final (status, label, tone) in cases) {
    testWidgets('$status shows "$label" in ${tone.name}', (tester) async {
      await pumpInApp(tester, VerificationBadge(status: status));

      expect(find.text(label), findsOneWidget);
      expect(tester.widget<AppBadge>(find.byType(AppBadge)).tone, tone);
    });
  }
}
