import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:server/src/http.dart' show RecordNotFound;
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/unused.dart';

/// Professors in memory, in name order, like the Postgres repository.
final class MemoryProfessors implements ProfessorRepository {
  MemoryProfessors(this.profiles, {this.listings = const [], this.slots = const []});

  final List<ProfessorProfile> profiles;
  final List<Listing> listings;
  final List<Slot> slots;

  @override
  Future<ProfessorsPage> professors({int offset = 0, int limit = 20}) async {
    final page = profiles.skip(offset).take(limit).toList();
    return ProfessorsPage(
      items: [for (final profile in page) ProfessorSummary(profile: profile, listings: await listingsOf(profile.id))],
      nextOffset: offset + limit < profiles.length ? offset + limit : null,
    );
  }

  @override
  Future<ProfessorProfile> profile(UserId id) async =>
      profiles.where((profile) => profile.id == id).firstOrNull ?? (throw RecordNotFound('No professor $id'));

  @override
  Future<List<Listing>> listingsOf(UserId professor) async => [
    for (final listing in listings)
      if (listing.professorId == professor) listing,
  ];

  @override
  Future<List<Slot>> slotsOf(UserId professor) async => [
    for (final slot in slots)
      if (slot.professorId == professor) slot,
  ];

  @override
  Future<Slot?> findSlot(SlotId id) async => slots.where((slot) => slot.id == id).firstOrNull;
}

/// Only what the public routes read from lessons: the taken slots.
final class TakenSlotsOnly implements LessonRepository {
  TakenSlotsOnly(this.taken);

  final Map<UserId, Set<SlotId>> taken;

  @override
  Future<Set<SlotId>> takenSlotsOf(UserId professor) async => taken[professor] ?? {};

  @override
  Never noSuchMethod(Invocation invocation) => throw StateError('The public routes read only taken slots');
}

const admin = User(id: UserId('jovana'), name: 'Jovana Ilić', role: Role.admin);
const student = User(id: UserId('ana'), name: 'Ana Marković', role: Role.student);

void main() {
  final at = DateTime.utc(2026, 11, 10, 8);
  final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jovan').valueOrNull!;
  final reason = RejectionReason.parse('Diploma nije čitljiva.').valueOrNull!;

  final milica = ProfessorProfile(
    id: const UserId('milica'),
    fullName: 'Milica Jovanović',
    city: City.belgrade,
    bio: 'Matematika.',
    verification: Verified(by: admin.id, at: at),
  );
  final jovan = ProfessorProfile(
    id: const UserId('jovan'),
    fullName: 'Jovan Marković',
    city: City.noviSad,
    bio: 'Fizika.',
    verification: AwaitingReview(submittedAt: at, diplomaFile: 'diplome/jovan.pdf', linkedIn: linkedIn),
  );
  final luka = ProfessorProfile(
    id: const UserId('luka'),
    fullName: 'Luka Popović',
    city: City.belgrade,
    bio: 'Istorija.',
    verification: VerificationRejected(by: admin.id, at: at, reason: reason),
  );
  final listing = Listing(
    id: const ListingId('l-math'),
    professorId: milica.id,
    subject: Subject.mathematics,
    level: Level.highSchool,
    city: City.belgrade,
    description: 'Analiza i algebra',
    price: Price.parse(2500).valueOrNull!,
    duration: LessonDuration.minutes60,
  );
  final slots = [
    Slot(
      id: const SlotId('s-1'),
      listingId: listing.id,
      professorId: milica.id,
      start: DateTime.utc(2026, 12, 1, 10),
      duration: LessonDuration.minutes60,
    ),
    Slot(
      id: const SlotId('s-2'),
      listingId: listing.id,
      professorId: milica.id,
      start: DateTime.utc(2026, 12, 1, 12),
      duration: LessonDuration.minutes60,
    ),
  ];

  late RelicServer server;
  late Uri base;
  final sessions = testSessions();

  setUpAll(() async {
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      buildHandler(
        corsOrigins: const [],
        lessons: TakenSlotsOnly({
          milica.id: {const SlotId('s-2')},
        }),
        professors: MemoryProfessors([jovan, luka, milica], listings: [listing], slots: slots),
        verifications: UnusedVerifications(),
        sessions: sessions,
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });
  tearDownAll(() => server.close());

  Future<http.Response> get(String path, {Map<String, String>? query, User? as}) => http.get(
    base.replace(path: path, queryParameters: query),
    headers: {'Authorization': ?(as == null ? null : 'Bearer ${sessions.issue(as)}')},
  );

  Object? bodyOf(http.Response response) => jsonDecode(response.body);

  Future<Map<String, Object?>> verificationAs(User? viewer, String professor) async {
    final response = await get(ApiPaths.professor(professor), as: viewer);
    expect(response.statusCode, 200);
    return ProfessorProfileDto.fromJson(bodyOf(response)! as Map<String, Object?>).verification.toJson();
  }

  group('who sees what of a profile', () {
    test('a visitor, without signing in, sees a profile awaiting review only as not verified', () async {
      expect(await verificationAs(null, 'jovan'), {'type': 'not_verified'});
      expect(await verificationAs(null, 'luka'), {'type': 'not_verified'});
    });

    test('a student does not see the diploma, the LinkedIn or the reason either', () async {
      expect(await verificationAs(student, 'jovan'), {'type': 'not_verified'});
      expect(await verificationAs(student, 'luka'), {'type': 'not_verified'});
    });

    test('a verified professor is shown as verified to everyone', () async {
      expect((await verificationAs(null, 'milica'))['type'], 'verified');
    });

    test('the admin sees the diploma, the LinkedIn and the reason', () async {
      final awaiting = await verificationAs(admin, 'jovan');
      expect(awaiting['type'], 'awaiting_review');
      expect(awaiting['diplomaFile'], 'diplome/jovan.pdf');
      expect(awaiting['linkedIn'], 'https://www.linkedin.com/in/jovan');
      expect((await verificationAs(admin, 'luka'))['reason'], 'Diploma nije čitljiva.');
    });

    test('a bad token is treated like no token, not refused', () async {
      final response = await http.get(
        base.replace(path: ApiPaths.professor('jovan')),
        headers: {'Authorization': 'Bearer not-a-token'},
      );

      expect(response.statusCode, 200);
      expect((bodyOf(response)! as Map<String, Object?>)['verification'], {'type': 'not_verified'});
    });

    test('an unknown professor is 404', () async {
      final response = await get(ApiPaths.professor('nobody'));

      expect(response.statusCode, 404);
      expect((bodyOf(response)! as Map<String, Object?>)['code'], ErrorCodes.notFound);
    });
  });

  group('the list of professors comes in pages', () {
    ProfessorsPageDto pageOf(http.Response response) =>
        ProfessorsPageDto.fromJson(bodyOf(response)! as Map<String, Object?>);

    test('the second page follows the first, and the last one has no next offset', () async {
      final first = pageOf(await get(ApiPaths.professors, query: {ApiQuery.limit: '2'}));
      final second = pageOf(
        await get(ApiPaths.professors, query: {ApiQuery.offset: '${first.nextOffset}', ApiQuery.limit: '2'}),
      );

      expect([for (final item in first.items) item.profile.id], ['jovan', 'luka']);
      expect(first.nextOffset, 2);
      expect([for (final item in second.items) item.profile.id], ['milica']);
      expect(second.nextOffset, isNull);
    });

    test('a visitor sees the list without the verification details', () async {
      final page = pageOf(await get(ApiPaths.professors));

      expect(
        [for (final item in page.items) item.profile.verification.type],
        ['not_verified', 'not_verified', 'verified'],
      );
      expect(page.items.last.listings.single.priceRsd, 2500);
    });

    test('an offset or a limit that is not a whole number, or too small, is 400', () async {
      for (final query in [
        {ApiQuery.offset: 'x'},
        {ApiQuery.offset: '-1'},
        {ApiQuery.limit: '0'},
        {ApiQuery.limit: '2.5'},
      ]) {
        final response = await get(ApiPaths.professors, query: query);
        expect(response.statusCode, 400, reason: '$query');
        expect((bodyOf(response)! as Map<String, Object?>)['code'], ErrorCodes.badRequest, reason: '$query');
      }
    });

    test('a limit over the maximum is cut to the maximum', () async {
      final response = await get(ApiPaths.professors, query: {ApiQuery.limit: '1000'});

      expect(response.statusCode, 200);
      expect(pageOf(response).items, hasLength(3));
    });
  });

  test('listings, slots and taken slots of a professor are public', () async {
    final listings = await get(ApiPaths.listingsOf('milica'));
    final allSlots = await get(ApiPaths.slotsOf('milica'));
    final taken = await get(ApiPaths.takenSlotsOf('milica'));

    expect((bodyOf(listings)! as List<Object?>).single, listing.toDtoJson());
    expect(
      [for (final slot in bodyOf(allSlots)! as List<Object?>) (slot! as Map<String, Object?>)['id']],
      ['s-1', 's-2'],
    );
    expect(bodyOf(taken), {
      'slotIds': ['s-2'],
    });
  });
}

extension on Listing {
  Map<String, Object?> toDtoJson() => {
    'id': id.value,
    'professorId': professorId.value,
    'subject': subject.name,
    'level': level.name,
    'city': city.name,
    'description': description,
    'priceRsd': price.dinars,
    'durationMinutes': duration.minutes,
  };
}
