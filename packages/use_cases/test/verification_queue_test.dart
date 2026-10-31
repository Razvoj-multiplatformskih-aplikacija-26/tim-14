import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jelena-petrovic').valueOrNull!;

  ProfessorProfile profileOf(String id, {VerificationStatus verification = const NotVerified()}) =>
      ProfessorProfile(id: UserId(id), fullName: id, city: City.belgrade, bio: '', verification: verification);

  ProfessorProfile awaiting(String id, {required DateTime submittedAt}) => profileOf(
    id,
    verification: AwaitingReview(submittedAt: submittedAt, diplomaFile: 'diplomas/$id.pdf', linkedIn: linkedIn),
  );

  final submitted = awaiting('jelena', submittedAt: now.subtract(const Duration(days: 1)));

  group('GetVerificationQueue', () {
    test('returns only profiles awaiting review, oldest submission first', () async {
      final newer = awaiting('newer', submittedAt: now.subtract(const Duration(hours: 1)));
      final older = awaiting('older', submittedAt: now.subtract(const Duration(days: 3)));
      final repository = InMemoryVerificationRepository([
        profileOf('not-submitted'),
        newer,
        profileOf(
          'verified',
          verification: Verified(by: admin.id, at: now),
        ),
        profileOf(
          'rejected',
          verification: VerificationRejected(by: admin.id, at: now, reason: 'Nečitljivo.'),
        ),
        older,
      ]);

      final queue = await GetVerificationQueue(repository)();

      expect(queue, [older, newer]);
    });

    test('a repository error is passed on', () async {
      final repository = InMemoryVerificationRepository()..fail = true;

      expect(() => GetVerificationQueue(repository)(), throwsA(isA<RepositoryException>()));
    });
  });

  group('VerifyProfessor', () {
    test('admin verifies a submitted profile and it is saved', () async {
      final repository = InMemoryVerificationRepository([submitted]);
      final verify = VerifyProfessor(repository, FixedClock(now), admin);

      final result = await verify(submitted);

      expect(result.valueOrNull!.verification, Verified(by: admin.id, at: now));
      expect(repository.saveCalls, 1);
      expect(repository.profiles.single.verification, Verified(by: admin.id, at: now));
    });

    test('a professor cannot verify', () async {
      final repository = InMemoryVerificationRepository([submitted]);
      final verify = VerifyProfessor(repository, FixedClock(now), professor);

      final result = await verify(submitted);

      expect(result, const Failure<ProfessorProfile>(NotAllowed()));
      expect(repository.saveCalls, 0);
    });

    test('an already verified profile cannot be verified again', () async {
      final verified = profileOf(
        'jelena',
        verification: Verified(by: admin.id, at: now),
      );
      final repository = InMemoryVerificationRepository([verified]);
      final verify = VerifyProfessor(repository, FixedClock(now), admin);

      final result = await verify(verified);

      expect(result.errorOrNull, isA<InvalidVerificationTransition>());
      expect(repository.saveCalls, 0);
    });
  });

  group('RejectProfessor', () {
    test('admin rejects with a reason and it is saved', () async {
      final repository = InMemoryVerificationRepository([submitted]);
      final reject = RejectProfessor(repository, FixedClock(now), admin);

      final result = await reject(submitted, reason: '  Diploma nije čitljiva.  ');

      final rejected = VerificationRejected(by: admin.id, at: now, reason: 'Diploma nije čitljiva.');
      expect(result.valueOrNull!.verification, rejected);
      expect(repository.saveCalls, 1);
      expect(repository.profiles.single.verification, rejected);
    });

    test('a rejection needs a reason', () async {
      final repository = InMemoryVerificationRepository([submitted]);
      final reject = RejectProfessor(repository, FixedClock(now), admin);

      final result = await reject(submitted, reason: '   ');

      expect(result, const Failure<ProfessorProfile>(MissingRejectionReason()));
      expect(repository.saveCalls, 0);
      expect(repository.profiles.single, submitted);
    });

    test('a professor cannot reject', () async {
      final repository = InMemoryVerificationRepository([submitted]);
      final reject = RejectProfessor(repository, FixedClock(now), professor);

      final result = await reject(submitted, reason: 'Ne.');

      expect(result, const Failure<ProfessorProfile>(NotAllowed()));
      expect(repository.saveCalls, 0);
    });
  });
}
