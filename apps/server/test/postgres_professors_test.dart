@Tags(['db'])
library;

import 'package:domain/domain.dart';
import 'package:server/server.dart';
import 'package:server/src/http.dart' show RecordNotFound;
import 'package:test/test.dart';

import 'support/fixture.dart';
import 'support/test_database.dart';

final milica = ProfessorProfile(
  id: const UserId('milica'),
  fullName: 'Milica Petrović',
  city: City.belgrade,
  bio: 'Matematika za srednju školu.',
  education: const [(institution: 'Matematički fakultet', title: 'Master matematike', fromYear: 2012, toYear: 2017)],
  experience: const [(employer: 'Treća beogradska gimnazija', title: 'Profesor', fromYear: 2017, toYear: null)],
  verification: Verified(by: const UserId('jovana'), at: DateTime.utc(2026, 10, 2, 12)),
);

final jovan = ProfessorProfile(
  id: const UserId('jovan'),
  fullName: 'Jovan Marković',
  city: City.noviSad,
  bio: 'Fizika za fakultet.',
  verification: AwaitingReview(
    submittedAt: DateTime.utc(2026, 11, 10, 8, 30),
    diplomaFile: 'diplome/jovan.pdf',
    linkedIn: LinkedInUrl.parse('https://www.linkedin.com/in/jovan').valueOrNull!,
  ),
);

final luka = ProfessorProfile(
  id: const UserId('luka'),
  fullName: 'Luka Popović',
  city: City.kragujevac,
  bio: 'Istorija.',
  verification: VerificationRejected(
    by: const UserId('jovana'),
    at: DateTime.utc(2026, 10, 21, 10),
    reason: RejectionReason.parse('Diploma na slici nije čitljiva.').valueOrNull!,
  ),
);

const sara = ProfessorProfile(
  id: UserId('sara'),
  fullName: 'Sara Nikolić',
  city: City.subotica,
  bio: 'Engleski jezik.',
);

final physics = Listing(
  id: const ListingId('l-physics'),
  professorId: const UserId('jovan'),
  subject: Subject.physics,
  level: Level.university,
  city: City.noviSad,
  description: 'Fizika 1',
  price: Price.parse(1800).valueOrNull!,
  duration: LessonDuration.minutes45,
);

void main() {
  late Database database;
  late PostgresProfessors professors;

  setUpAll(() async {
    database = await createTestDatabase();
    professors = PostgresProfessors(database);
  });
  setUp(() async {
    await truncateTables(database);
    await insertFixture(database);
  });
  tearDownAll(() => database.close());

  test('a profile row becomes the domain profile, in every verification state', () async {
    expect(await professors.profile(const UserId('milica')), milica);
    expect(await professors.profile(const UserId('jovan')), jovan);
    expect(await professors.profile(const UserId('luka')), luka);
    expect(await professors.profile(const UserId('sara')), sara);
  });

  test('an unknown professor is RecordNotFound, which the server answers with 404', () async {
    await expectLater(professors.profile(const UserId('nobody')), throwsA(isA<RecordNotFound>()));
  });

  test('pages go by name, carry their listings, and the last one has no next offset', () async {
    final first = await professors.professors(limit: 2);
    final second = await professors.professors(offset: 2, limit: 2);
    final last = await professors.professors(offset: 4, limit: 2);

    expect([for (final item in first.items) item.profile.fullName], ['Jovan Marković', 'Luka Popović']);
    expect(first.items.first.listings, [physics]);
    expect(first.items.last.listings, isEmpty);
    expect(first.nextOffset, 2);

    expect([for (final item in second.items) item.profile.id], [const UserId('milica'), const UserId('sara')]);
    expect(
      [for (final listing in second.items.first.listings) listing.id],
      [const ListingId('l-exam'), const ListingId('l-math')],
    );
    expect(second.nextOffset, 4);

    expect([for (final item in last.items) item.profile.id], [const UserId('vesna')]);
    expect(last.nextOffset, isNull);

    final pastTheEnd = await professors.professors(offset: 10);
    expect(pastTheEnd.items, isEmpty);
    expect(pastTheEnd.nextOffset, isNull);
  });

  test('listingsOf returns only that professor’s listings', () async {
    expect(await professors.listingsOf(const UserId('jovan')), [physics]);
    expect(await professors.listingsOf(const UserId('sara')), isEmpty);
  });

  test('slotsOf returns that professor’s slots, earliest first', () async {
    final slots = await professors.slotsOf(const UserId('milica'));

    expect([for (final slot in slots) slot.id], [const SlotId('s-3'), const SlotId('s-1'), const SlotId('s-2')]);
    expect(slots.first.duration, LessonDuration.minutes90);
    expect(slots.first.start, DateTime.utc(2026, 11, 30, 16));
  });

  test('findSlot finds a slot by id, or returns null', () async {
    expect(
      await professors.findSlot(const SlotId('s-4')),
      Slot(
        id: const SlotId('s-4'),
        listingId: const ListingId('l-physics'),
        professorId: const UserId('jovan'),
        start: DateTime.utc(2026, 12, 2, 9),
        duration: LessonDuration.minutes45,
      ),
    );
    expect(await professors.findSlot(const SlotId('nope')), isNull);
  });
}
