import '../access_policy.dart';
import '../user.dart';
import 'professor_profile.dart';
import 'verification_status.dart';

// Profil onako kako ga vidi [viewer] (null je posetilac bez prijave).
// Ko ne sme da vidi detalje verifikacije, za profil koji čeka proveru ili je odbijen vidi samo
// da profesor nije verifikovan. Tako diploma, LinkedIn i razlog odbijanja ne izlaze iz servera.
ProfessorProfile visibleTo(ProfessorProfile profile, User? viewer) {
  if (AccessPolicy.canSeeVerificationDetails(viewer)) {
    return profile;
  }
  return switch (profile.verification) {
    NotVerified() || Verified() => profile,
    AwaitingReview() || VerificationRejected() => profile.copyWith(verification: const NotVerified()),
  };
}
