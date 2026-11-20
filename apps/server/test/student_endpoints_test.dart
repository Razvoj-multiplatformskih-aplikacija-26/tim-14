import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/memory.dart';
import 'support/unused.dart';

final fixedNow = DateTime.utc(2026, 11, 20, 10);

final class FixedClock implements Clock {
  @override
  DateTime now() => fixedNow;
}

const ana = User(id: UserId('ana'), name: 'Ana Marković', role: Role.student);
const nikola = User(id: UserId('nikola'), name: 'Nikola Petrović', role: Role.student);
const milica = User(id: UserId('milica'), name: 'Milica', role: Role.professor);
const jelena = User(id: UserId('jelena'), name: 'Jelena Marković', role: Role.professor);

void main() {
  final inThreeDays = fixedNow.add(const Duration(days: 3));
  final inTenHours = fixedNow.add(const Duration(hours: 10));

  // The profile spells the name in full; a new lesson must copy this one, not the name in the token.
  const milicasProfile = ProfessorProfile(
    id: UserId('milica'),
    fullName: 'Milica Jovanović',
    city: City.belgrade,
    bio: '',
  );

  Slot slot(String id, DateTime start) => Slot(
    id: SlotId(id),
    listingId: const ListingId('l-math'),
    professorId: milica.id,
    start: start,
    duration: LessonDuration.minutes60,
  );

  Lesson lesson(String id, User student, DateTime start, LessonStatus status) => Lesson(
    id: LessonId(id),
    slotId: SlotId('s-$id'),
    listingId: const ListingId('l-math'),
    professorId: milica.id,
    professorName: milicasProfile.fullName,
    studentId: student.id,
    studentName: student.name,
    start: start,
    duration: LessonDuration.minutes60,
    message: RequestMessage.parse('Zdravo').valueOrNull!,
    createdAt: fixedNow.subtract(const Duration(days: 1)),
    status: status,
  );

  final slots = [
    slot('s-free-1', inThreeDays),
    slot('s-free-2', inThreeDays.add(const Duration(hours: 2))),
    slot('s-free-3', inThreeDays.add(const Duration(hours: 4))),
    slot('s-soon', inTenHours),
  ];

  late MemoryLessons lessons;
  late RelicServer server;
  late Uri base;
  final sessions = testSessions();

  setUp(() async {
    lessons = MemoryLessons([
      // Ana has two pending requests, so her third goes through and her fourth does not.
      lesson('ana-pending-1', ana, inThreeDays.add(const Duration(days: 1)), const Pending()),
      lesson('ana-pending-2', ana, inThreeDays.add(const Duration(days: 2)), const Pending()),
      lesson('ana-far', ana, inThreeDays, Confirmed(at: fixedNow)),
      lesson('ana-near', ana, inTenHours, Confirmed(at: fixedNow)),
      lesson('nikola-confirmed', nikola, inThreeDays, Confirmed(at: fixedNow)),
    ]);
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      buildHandler(
        corsOrigins: const [],
        lessons: lessons,
        professors: MemoryProfessors([milicasProfile], slots: slots),
        verifications: UnusedVerifications(),
        sessions: sessions,
        clock: FixedClock(),
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });
  tearDown(() => server.close());

  Map<String, String> headers(User? as, {bool json = false}) => {
    'Authorization': ?(as == null ? null : 'Bearer ${sessions.issue(as)}'),
    if (json) 'Content-Type': 'application/json',
  };

  Future<http.Response> get(String path, {User? as, Map<String, String>? query}) => http.get(
    base.replace(path: path, queryParameters: query),
    headers: headers(as),
  );

  Future<http.Response> post(String path, {User? as, Map<String, Object?>? body}) => http.post(
    base.replace(path: path),
    headers: headers(as, json: body != null),
    body: body == null ? null : jsonEncode(body),
  );

  Object? bodyOf(http.Response response) => jsonDecode(response.body);

  Map<String, Object?> problemOf(http.Response response) => bodyOf(response)! as Map<String, Object?>;

  List<String> idsOf(http.Response response) => [
    for (final lesson in bodyOf(response)! as List<Object?>) (lesson! as Map<String, Object?>)['id']! as String,
  ];

  Future<http.Response> request(String slotId, {User as = ana, String message = 'Treba mi pomoć oko integrala.'}) =>
      post(
        ApiPaths.lessons,
        as: as,
        body: NewLessonDto(slotId: slotId, message: message).toJson(),
      );

  group('reading lessons', () {
    test('a student reads her own lessons', () async {
      final response = await get(ApiPaths.lessons, as: ana, query: {ApiQuery.student: 'ana'});

      expect(response.statusCode, 200);
      expect(idsOf(response), unorderedEquals(['ana-pending-1', 'ana-pending-2', 'ana-far', 'ana-near']));
    });

    test("the id in the query is only a filter: another student's lessons come back empty", () async {
      final response = await get(ApiPaths.lessons, as: nikola, query: {ApiQuery.student: 'ana'});

      expect(response.statusCode, 200);
      expect(idsOf(response), isEmpty);
    });

    test("a student who asks for a professor's lessons gets only her own", () async {
      final response = await get(ApiPaths.lessons, as: nikola, query: {ApiQuery.professor: 'milica'});

      expect(idsOf(response), ['nikola-confirmed']);
    });

    test('the professor reads all her lessons, the backoffice way', () async {
      final response = await get(ApiPaths.lessons, as: milica, query: {ApiQuery.professor: 'milica'});

      expect(idsOf(response), hasLength(5));
      final first = bodyOf(response)! as List<Object?>;
      expect((first.first! as Map<String, Object?>)['studentName'], isNotEmpty);
    });

    test('no filter, or two of them, is 400', () async {
      for (final query in <Map<String, String>?>[
        null,
        {ApiQuery.student: 'ana', ApiQuery.slot: 's-ana-far'},
      ]) {
        final response = await get(ApiPaths.lessons, as: ana, query: query);
        expect(response.statusCode, 400, reason: '$query');
        expect(problemOf(response)['code'], ErrorCodes.badRequest);
      }
    });

    test('one lesson: her own is 200, someone else\'s and a missing one are both 404', () async {
      expect((await get(ApiPaths.lesson('ana-far'), as: ana)).statusCode, 200);

      for (final id in ['nikola-confirmed', 'no-such-lesson']) {
        final response = await get(ApiPaths.lesson(id), as: ana);
        expect(response.statusCode, 404, reason: id);
        expect(problemOf(response)['code'], ErrorCodes.notFound);
      }
    });

    test('without signing in it is 401', () async {
      final response = await get(ApiPaths.lessons, query: {ApiQuery.student: 'ana'});

      expect(response.statusCode, 401);
      expect(problemOf(response)['code'], ErrorCodes.signInRequired);
    });
  });

  group('a new request', () {
    test('is 201, pending, with the names from the profile and the token', () async {
      final response = await request('s-free-1');

      expect(response.statusCode, 201);
      final created = LessonDto.fromJson(bodyOf(response)! as Map<String, Object?>);
      expect(created.status.type, LessonStatusDto.pending);
      expect(created.studentId, 'ana');
      expect(created.studentName, 'Ana Marković');
      expect(created.professorName, 'Milica Jovanović');
      expect(created.start, inThreeDays);
      expect(lessons.stored(LessonId(created.id)), isNotNull);
    });

    test('a message of 301 characters is 422 with the length and the limit', () async {
      final response = await request('s-free-1', message: 'a' * 301);

      expect(response.statusCode, 422);
      expect(problemOf(response), containsPair('code', ErrorCodes.invalidRequestMessage));
      expect(problemOf(response), containsPair('value', 301));
      expect(problemOf(response), containsPair('max', 300));
    });

    test('a slot less than 24 hours away is 422 with the notice in minutes', () async {
      final response = await request('s-soon');

      expect(response.statusCode, 422);
      expect(problemOf(response)['code'], ErrorCodes.tooSoonToRequest);
      expect(problemOf(response)['minutes'], 24 * 60);
    });

    test("Ana's third request goes through and her fourth is 409 with the limit", () async {
      expect((await request('s-free-1')).statusCode, 201);

      final fourth = await request('s-free-2');

      expect(fourth.statusCode, 409);
      expect(problemOf(fourth)['code'], ErrorCodes.tooManyPendingRequests);
      expect(problemOf(fourth)['max'], 3);
    });

    test('an unknown slot is 404 and a professor is not allowed to request', () async {
      expect((await request('no-such-slot')).statusCode, 404);

      final asProfessor = await request('s-free-3', as: jelena);
      expect(asProfessor.statusCode, 403);
      expect(problemOf(asProfessor)['code'], ErrorCodes.notAllowed);
    });

    test('a body without a message is 400', () async {
      final response = await post(ApiPaths.lessons, as: ana, body: {'slotId': 's-free-1'});

      expect(response.statusCode, 400);
    });
  });

  group('withdrawing a request', () {
    test('her own pending request is withdrawn', () async {
      final response = await post(ApiPaths.withdrawal('ana-pending-1'), as: ana);

      expect(response.statusCode, 200);
      expect(lessons.stored(const LessonId('ana-pending-1'))!.status, isA<Cancelled>());
    });

    test('a confirmed lesson is not a request any more: 409 with both statuses', () async {
      final response = await post(ApiPaths.withdrawal('ana-far'), as: ana);

      expect(response.statusCode, 409);
      expect(problemOf(response)['code'], ErrorCodes.invalidTransition);
      expect((problemOf(response)['from']! as Map<String, Object?>)['type'], 'confirmed');
    });

    test('the second of two withdrawals of the same request is refused, and nothing changes twice', () async {
      expect((await post(ApiPaths.withdrawal('ana-pending-2'), as: ana)).statusCode, 200);

      final late = await post(ApiPaths.withdrawal('ana-pending-2'), as: ana);

      expect(late.statusCode, 409);
      expect(problemOf(late)['code'], ErrorCodes.invalidTransition);
    });
  });

  group('cancelling a confirmed lesson', () {
    test('more than 24 hours ahead it is cancelled', () async {
      final response = await post(ApiPaths.cancellation('ana-far'), as: ana);

      expect(response.statusCode, 200);
      expect(LessonDto.fromJson(bodyOf(response)! as Map<String, Object?>).status.by, 'ana');
    });

    test('less than 24 hours ahead it is 422 with the notice', () async {
      final response = await post(ApiPaths.cancellation('ana-near'), as: ana);

      expect(response.statusCode, 422);
      expect(problemOf(response)['code'], ErrorCodes.cancellationTooLate);
      expect(problemOf(response)['minutes'], 24 * 60);
    });

    test("Ana cancelling Nikola's lesson is 404, and the lesson stays confirmed", () async {
      final response = await post(ApiPaths.cancellation('nikola-confirmed'), as: ana);

      expect(response.statusCode, 404);
      expect(lessons.stored(const LessonId('nikola-confirmed'))!.status, isA<Confirmed>());
    });

    test('the professor of the lesson may cancel it too', () async {
      final response = await post(ApiPaths.cancellation('nikola-confirmed'), as: milica);

      expect(response.statusCode, 200);
      expect(LessonDto.fromJson(bodyOf(response)! as Map<String, Object?>).status.by, 'milica');
    });
  });
}
