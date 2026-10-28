import '../access_policy.dart';
import '../errors.dart';
import '../result.dart';
import '../user.dart';
import 'linkedin_url.dart';
import 'professor_profile.dart';
import 'verification_status.dart';

Result<ProfessorProfile> submitVerification(
  ProfessorProfile profile, {
  required User by,
  required String diplomaFile,
  required LinkedInUrl linkedIn,
  required DateTime now,
}) {
  if (!AccessPolicy.canSubmitVerification(by, profile)) return const Failure(NotAllowed());
  final next = AwaitingReview(submittedAt: now.toUtc(), diplomaFile: diplomaFile, linkedIn: linkedIn);
  return _moveTo(profile, next);
}

Result<ProfessorProfile> verifyProfessor(ProfessorProfile profile, {required User by, required DateTime now}) {
  if (!AccessPolicy.canDecideVerification(by)) return const Failure(NotAllowed());
  return _moveTo(profile, Verified(by: by.id, at: now.toUtc()));
}

Result<ProfessorProfile> rejectVerification(
  ProfessorProfile profile, {
  required User by,
  required String reason,
  required DateTime now,
}) {
  if (!AccessPolicy.canDecideVerification(by)) return const Failure(NotAllowed());
  final trimmed = reason.trim();
  if (trimmed.isEmpty) return const Failure(MissingRejectionReason());
  return _moveTo(profile, VerificationRejected(by: by.id, at: now.toUtc(), reason: trimmed));
}

Result<ProfessorProfile> _moveTo(ProfessorProfile profile, VerificationStatus next) {
  if (!profile.verification.canTransitionTo(next)) {
    return Failure(InvalidVerificationTransition(from: profile.verification, to: next));
  }
  return Success(profile.copyWith(verification: next));
}
