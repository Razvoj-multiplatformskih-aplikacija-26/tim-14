import 'package:domain/domain.dart';

import '../ports/verification_repository.dart';

final class GetVerificationQueue {
  GetVerificationQueue(this._verifications);

  final VerificationRepository _verifications;

  Future<List<ProfessorProfile>> call() async {
    final profiles = await _verifications.queue();
    final waiting = profiles.where((profile) => profile.verification is AwaitingReview).toList();
    waiting.sort((a, b) => _submittedAt(a).compareTo(_submittedAt(b)));
    return waiting;
  }

  DateTime _submittedAt(ProfessorProfile profile) => (profile.verification as AwaitingReview).submittedAt;
}
