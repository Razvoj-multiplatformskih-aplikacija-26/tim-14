@Tags(['db'])
library;

import 'package:domain/domain.dart';
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/fixture.dart';
import 'support/test_database.dart';

const jovana = User(id: UserId('jovana'), name: 'Jovana Admin', role: Role.admin);
const petar = User(id: UserId('petar'), name: 'Petar Admin', role: Role.admin);

/// Microseconds on purpose: Postgres keeps them, so the decision time must come back exactly.
final decidedAt = DateTime.utc(2026, 11, 19, 20, 15, 30, 123, 456);

final class FixedClock implements Clock {
  @override
  DateTime now() => decidedAt;
}

void main() {
  late Database database;
  late PostgresVerifications verifications;

  setUpAll(() async {
    database = await createTestDatabase();
    verifications = PostgresVerifications(database);
  });
  setUp(() async {
    await truncateTables(database);
    await insertFixture(database);
    await insertRows(database, "INSERT INTO users (id, name, role) VALUES ('petar', 'Petar Admin', 'admin')");
  });
  tearDownAll(() => database.close());

  Future<ProfessorProfile> load(String id) async => (await verifications.find(UserId(id)))!;

  test('the queue holds only profiles awaiting review, the longest-waiting first', () async {
    final queue = await verifications.queue();

    expect([for (final profile in queue) profile.id], [const UserId('vesna'), const UserId('jovan')]);
  });

  test('find returns a profile in any state, or null', () async {
    expect((await load('sara')).verification, const NotVerified());
    expect(await verifications.find(const UserId('nobody')), isNull);
  });

  test('a verification is stored and leaves the queue', () async {
    final result = await VerifyProfessor(verifications, FixedClock(), jovana)(await load('jovan'));

    expect(result.isSuccess, isTrue);
    expect((await load('jovan')).verification, Verified(by: jovana.id, at: decidedAt));
    expect([for (final profile in await verifications.queue()) profile.id], [const UserId('vesna')]);
  });

  test('a rejection is stored with its reason', () async {
    final result = await RejectProfessor(verifications, FixedClock(), jovana)(
      await load('vesna'),
      reason: 'LinkedIn profil ne postoji.',
    );

    expect(result.isSuccess, isTrue);
    expect(
      (await load('vesna')).verification,
      VerificationRejected(
        by: jovana.id,
        at: decidedAt,
        reason: RejectionReason.parse('LinkedIn profil ne postoji.').valueOrNull!,
      ),
    );
  });

  test('when two admins decide the same profile, the second one is refused and the first decision stays', () async {
    // Both admins opened the queue while Jovan was still awaiting review.
    final seenByJovana = await load('jovan');
    final seenByPetar = await load('jovan');

    final first = await VerifyProfessor(verifications, FixedClock(), jovana)(seenByJovana);
    final second = await RejectProfessor(verifications, FixedClock(), petar)(
      seenByPetar,
      reason: 'Diploma nije priložena.',
    );

    expect(first.isSuccess, isTrue);
    expect(
      second,
      Failure<ProfessorProfile>(
        InvalidVerificationTransition(
          from: Verified(by: jovana.id, at: decidedAt),
          to: VerificationRejected(
            by: petar.id,
            at: decidedAt,
            reason: RejectionReason.parse('Diploma nije priložena.').valueOrNull!,
          ),
        ),
      ),
    );
    expect((await load('jovan')).verification, Verified(by: jovana.id, at: decidedAt));
  });

  test('two admins at the same moment: exactly one decision is written', () async {
    final seen = await load('jovan');

    final results = await Future.wait([
      VerifyProfessor(verifications, FixedClock(), jovana)(seen),
      RejectProfessor(verifications, FixedClock(), petar)(seen, reason: 'Diploma nije priložena.'),
    ]);

    expect(results.where((result) => result.isSuccess), hasLength(1));
    expect(results.where((result) => result.errorOrNull is InvalidVerificationTransition), hasLength(1));
  });

  test('a decision about a profile that does not exist is NotFound', () async {
    final nobody = ProfessorProfile(
      id: const UserId('nobody'),
      fullName: 'Niko Nikić',
      city: City.nis,
      bio: '',
      verification: Verified(by: jovana.id, at: decidedAt),
    );

    expect(await verifications.save(nobody, from: const NotVerified()), const Failure<ProfessorProfile>(NotFound()));
  });

  test('only an admin decision is saved here', () async {
    final jovan = await load('jovan');

    await expectLater(verifications.save(jovan, from: const NotVerified()), throwsArgumentError);
  });
}
