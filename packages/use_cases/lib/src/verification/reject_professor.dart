import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/verification_repository.dart';

final class RejectProfessor {
  RejectProfessor(this._verifications, this._clock, this._me);

  final VerificationRepository _verifications;
  final Clock _clock;
  final User _me;

  Future<Result<ProfessorProfile>> call(ProfessorProfile profile, {required String reason}) async {
    final parsed = RejectionReason.parse(reason);
    if (parsed is Failure<RejectionReason>) {
      return Failure(parsed.error);
    }

    final result = rejectVerification(profile, by: _me, reason: parsed.valueOrNull!, now: _clock.now());

    if (result is Success<ProfessorProfile>) {
      final value = result.value;
      return Success(await _verifications.save(value));
    }
    return result;
  }
}
