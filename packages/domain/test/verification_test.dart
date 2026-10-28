import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const diplomaFile = 'diplomas/u-professor.pdf';
  const profile = ProfessorProfile(
    id: UserId('u-professor'),
    fullName: 'Jelena Petrović',
    city: City.belgrade,
    bio: 'Profesorka matematike.',
  );
  final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jelena-petrovic').valueOrNull!;
  final later = now.add(const Duration(days: 1));
  final submitted = submitVerification(
    profile,
    by: professor,
    diplomaFile: diplomaFile,
    linkedIn: linkedIn,
    now: now,
  ).valueOrNull!;

  group('canTransitionTo', () {
    final statuses = <VerificationStatus>[
      const NotVerified(),
      AwaitingReview(submittedAt: now, diplomaFile: diplomaFile, linkedIn: linkedIn),
      Verified(by: admin.id, at: now),
      VerificationRejected(by: admin.id, at: now, reason: 'Nečitljivo.'),
    ];
    final allowed = {
      (NotVerified, AwaitingReview),
      (AwaitingReview, Verified),
      (AwaitingReview, VerificationRejected),
      (VerificationRejected, AwaitingReview),
    };
    for (final from in statuses) {
      for (final to in statuses) {
        final expected = allowed.contains((from.runtimeType, to.runtimeType));
        test('${from.runtimeType} -> ${to.runtimeType} is ${expected ? 'allowed' : 'refused'}', () {
          expect(from.canTransitionTo(to), expected);
        });
      }
    }
  });

  test('professor submits documents for review', () {
    expect(submitted.verification, AwaitingReview(submittedAt: now, diplomaFile: diplomaFile, linkedIn: linkedIn));
    expect(submitted.isVerified, isFalse);
  });

  test('nobody else can submit for the professor', () {
    for (final user in [otherProfessor, admin]) {
      final result = submitVerification(profile, by: user, diplomaFile: diplomaFile, linkedIn: linkedIn, now: now);
      expect(result.errorOrNull, isA<NotAllowed>());
    }
  });

  test('admin verifies a submitted profile', () {
    final verified = verifyProfessor(submitted, by: admin, now: later).valueOrNull!;
    expect(verified.verification, Verified(by: admin.id, at: later));
    expect(verified.isVerified, isTrue);
  });

  test('admin rejects with a reason', () {
    final rejected = rejectVerification(submitted, by: admin, reason: '  Diploma nije čitljiva.  ', now: later);
    expect(
      rejected.valueOrNull!.verification,
      VerificationRejected(by: admin.id, at: later, reason: 'Diploma nije čitljiva.'),
    );
  });

  test('a rejection needs a reason', () {
    final result = rejectVerification(submitted, by: admin, reason: '   ', now: later);
    expect(result.errorOrNull, isA<MissingRejectionReason>());
  });

  test('only admins decide', () {
    expect(verifyProfessor(submitted, by: professor, now: later).errorOrNull, isA<NotAllowed>());
    final rejected = rejectVerification(submitted, by: professor, reason: 'Ne.', now: later);
    expect(rejected.errorOrNull, isA<NotAllowed>());
  });

  test('cannot decide before the documents are submitted', () {
    expect(verifyProfessor(profile, by: admin, now: later).errorOrNull, isA<InvalidVerificationTransition>());
    final rejected = rejectVerification(profile, by: admin, reason: 'Nema diplome.', now: later);
    expect(rejected.errorOrNull, isA<InvalidVerificationTransition>());
  });

  test('professor resubmits after a rejection', () {
    final rejected = rejectVerification(submitted, by: admin, reason: 'Nečitljivo.', now: later).valueOrNull!;
    final resubmitted = submitVerification(
      rejected,
      by: professor,
      diplomaFile: diplomaFile,
      linkedIn: linkedIn,
      now: later,
    );
    expect(resubmitted.valueOrNull!.verification, isA<AwaitingReview>());
  });

  test('a verified professor cannot submit again', () {
    final verified = verifyProfessor(submitted, by: admin, now: later).valueOrNull!;
    final result = submitVerification(
      verified,
      by: professor,
      diplomaFile: diplomaFile,
      linkedIn: linkedIn,
      now: later,
    );
    expect(result.errorOrNull, isA<InvalidVerificationTransition>());
  });
}
