import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/verification_repository.dart';

final class VerifyProfessor {
  VerifyProfessor(this._verifications, this._clock, this._me);

  final VerificationRepository _verifications;
  final Clock _clock;
  final User _me;

  Future<Result<ProfessorProfile>> call(ProfessorProfile profile) async {
    final result = verifyProfessor(profile, by: _me, now: _clock.now());

    if (result is Success<ProfessorProfile>) {
      final value = result.value;
      return Success(await _verifications.save(value));
    }
    return result;
  }
}
