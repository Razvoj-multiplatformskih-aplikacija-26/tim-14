import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

import 'app_badge.dart';

/// Labels from Figma Panel · tutor › Obrazovanje, which shows all four states.
/// Figma adds the date to the verified label; that waits until there's Serbian date formatting.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      NotVerified() => ('Nepotvrđeno', BadgeTone.neutral),
      AwaitingReview() => ('Na proveri', BadgeTone.warning),
      Verified() => ('Potvrđeno', BadgeTone.verified),
      VerificationRejected() => ('Odbijeno', BadgeTone.destructive),
    };
    return AppBadge(label: label, tone: tone);
  }
}
