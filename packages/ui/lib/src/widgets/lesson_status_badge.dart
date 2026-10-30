import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

import 'app_badge.dart';

/// Warning while waiting for a decision, accent while upcoming, destructive when it went wrong, neutral once closed.
/// Pine stays reserved for verification.
class LessonStatusBadge extends StatelessWidget {
  const LessonStatusBadge({super.key, required this.status});

  final LessonStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      Pending() => ('Na čekanju', BadgeTone.warning),
      Confirmed() => ('Potvrđeno', BadgeTone.accent),
      Rejected(cause: RejectionCause.byProfessor) => ('Odbijeno', BadgeTone.destructive),
      Rejected(cause: RejectionCause.slotTaken) => ('Termin zauzet', BadgeTone.destructive),
      Cancelled() => ('Otkazano', BadgeTone.neutral),
      Held() => ('Održano', BadgeTone.neutral),
      NoShow() => ('Nedolazak', BadgeTone.destructive),
    };
    return AppBadge(label: label, tone: tone);
  }
}
