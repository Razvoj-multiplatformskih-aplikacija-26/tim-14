import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  const profile = ProfessorProfile(
    id: UserId('u-professor'),
    fullName: 'Jelena Petrović',
    city: City.belgrade,
    bio: 'Profesorka matematike.',
  );
  final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jelena-petrovic').valueOrNull!;
  final reason = RejectionReason.parse('Diploma nije čitljiva.').valueOrNull!;

  final awaiting = profile.copyWith(
    verification: AwaitingReview(submittedAt: now, diplomaFile: 'diplomas/jelena.pdf', linkedIn: linkedIn),
  );
  final rejected = profile.copyWith(
    verification: VerificationRejected(by: admin.id, at: now, reason: reason),
  );
  final verified = profile.copyWith(
    verification: Verified(by: admin.id, at: now),
  );

  // Posetilac bez prijave (null), učenik i profesor vide isto.
  final notAdmins = <String, User?>{'a visitor': null, 'a student': student, 'a professor': professor};

  for (final MapEntry(key: who, value: viewer) in notAdmins.entries) {
    group(who, () {
      test('sees a profile awaiting review only as not verified', () {
        expect(visibleTo(awaiting, viewer).verification, const TypeMatcher<NotVerified>());
      });

      test('sees a rejected profile only as not verified, without the reason', () {
        expect(visibleTo(rejected, viewer).verification, const TypeMatcher<NotVerified>());
      });

      test('sees a verified and a not verified profile as they are', () {
        expect(visibleTo(verified, viewer), verified);
        expect(visibleTo(profile, viewer), profile);
      });

      test('still sees the rest of the profile', () {
        final visible = visibleTo(awaiting, viewer);
        expect(visible.id, profile.id);
        expect(visible.fullName, profile.fullName);
        expect(visible.city, profile.city);
        expect(visible.bio, profile.bio);
      });
    });
  }

  test('the admin sees every profile with all its details', () {
    for (final shown in [profile, awaiting, rejected, verified]) {
      expect(visibleTo(shown, admin), shown);
    }
  });
}
