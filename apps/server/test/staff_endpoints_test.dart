@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart' show Sql;
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart' show Clock;

import 'support/fixture.dart';
import 'support/test_database.dart';
import 'support/unused.dart';

/// The users of the fixture, by id, so a test can call as one of them.
const fixtureUsers = {
  'jovana': User(id: UserId('jovana'), name: 'Jovana Admin', role: Role.admin),
  'milica': User(id: UserId('milica'), name: 'Milica Petrović', role: Role.professor),
  'jovan': User(id: UserId('jovan'), name: 'Jovan Marković', role: Role.professor),
  'ana': User(id: UserId('ana'), name: 'Ana Jovanović', role: Role.student),
  'nikola': User(id: UserId('nikola'), name: 'Nikola Ilić', role: Role.student),
  'marija': User(id: UserId('marija'), name: 'Marija Stojanović', role: Role.student),
};

/// Over a week before every fixture slot: nothing has started yet.
final beforeEverything = DateTime.utc(2026, 11, 19, 12);

/// Half an hour into slot s-1 (2026-12-01 10:00, 60 min): it has started, so held and no-show are allowed.
final duringS1 = DateTime.utc(2026, 12, 1, 10, 30);

/// A clock the test can move.
final class TestClock implements Clock {
  DateTime current = beforeEverything;

  @override
  DateTime now() => current;
}

/// The whole server over a real Postgres, called over real HTTP. In Spring terms: `@SpringBootTest` with a
/// Testcontainers database, rather than a `@WebMvcTest` with mocked repositories.
void main() {
  late Database database;
  late RelicServer server;
  late Uri base;
  final clock = TestClock();
  final sessions = testSessions();

  setUpAll(() async {
    database = await createTestDatabase();
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      buildHandler(
        corsOrigins: const [],
        lessons: PostgresLessons(database),
        verifications: PostgresVerifications(database),
        sessions: sessions,
        clock: clock,
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });
  setUp(() async {
    clock.current = beforeEverything;
    await truncateTables(database);
    await insertFixture(database);
  });
  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  /// A user of the fixture gets a token the server signed, the way the login issues it. Any other id gets a token
  /// the server never signed.
  String tokenFor(String id) => switch (fixtureUsers[id]) {
    final user? => sessions.issue(user),
    null => 'not-a-token-the-server-signed',
  };

  /// [as] is the caller's user id; the request carries `Authorization: Bearer <token>`.
  Map<String, String> headersFor(String? as, {bool json = false}) => {
    'Authorization': ?(as == null ? null : 'Bearer ${tokenFor(as)}'),
    if (json) 'Content-Type': 'application/json',
  };

  Future<http.Response> post(String path, {String? as, Map<String, Object?>? body}) => http.post(
    base.replace(path: path),
    headers: headersFor(as, json: body != null),
    body: body == null ? null : jsonEncode(body),
  );

  Future<http.Response> get(String path, {String? as}) => http.get(base.replace(path: path), headers: headersFor(as));

  Map<String, Object?> bodyOf(http.Response response) => jsonDecode(response.body) as Map<String, Object?>;

  Map<String, Object?> statusOf(Map<String, Object?> lesson) => lesson['status']! as Map<String, Object?>;

  Map<String, Object?> verificationOf(Map<String, Object?> profile) => profile['verification']! as Map<String, Object?>;

  Future<String> storedStatus(String lesson) => database.run(
    (db) async =>
        (await db.execute(
              Sql.named('SELECT status FROM lessons WHERE id = @id'),
              parameters: {'id': lesson},
            )).single.single!
            as String,
  );

  Future<String> storedVerification(String professor) => database.run(
    (db) async =>
        (await db.execute(
              Sql.named('SELECT verification FROM professor_profiles WHERE user_id = @id'),
              parameters: {'id': professor},
            )).single.single!
            as String,
  );

  group('signing in', () {
    setUp(() => insertLesson(database, 'l-ana', slot: 's-1', student: 'ana'));

    test('without an Authorization header it is 401, and the handler never runs', () async {
      final response = await post('/lessons/l-ana/confirmation');

      expect(response.statusCode, 401);
      expect(bodyOf(response)['code'], 'sign-in-required');
      expect(await storedStatus('l-ana'), 'pending');
    });

    test('a token the server did not sign is 401 session-expired, and the handler never runs', () async {
      final response = await post('/lessons/l-ana/confirmation', as: 'nobody');

      expect(response.statusCode, 401);
      expect(bodyOf(response)['code'], 'session-expired');
      expect(await storedStatus('l-ana'), 'pending');
    });

    test('the verification routes need it too', () async {
      final response = await get('/verifications');

      expect(response.statusCode, 401);
    });
  });

  group('confirmation', () {
    setUp(() async {
      await insertLesson(database, 'l-ana', slot: 's-1', student: 'ana');
      await insertLesson(database, 'l-nikola', slot: 's-1', student: 'nikola');
    });

    test('the professor confirms, and the other request for the slot is rejected with it', () async {
      final response = await post('/lessons/l-ana/confirmation', as: 'milica');

      expect(response.statusCode, 200);
      final body = bodyOf(response);
      final confirmed = body['confirmed']! as Map<String, Object?>;
      final rejected = body['rejected']! as List<Object?>;
      expect(confirmed['id'], 'l-ana');
      expect(statusOf(confirmed), {'type': 'confirmed', 'at': '2026-11-19T12:00:00.000Z'});
      expect(rejected, hasLength(1));
      expect(statusOf(rejected.single! as Map<String, Object?>), {
        'type': 'rejected',
        'cause': 'slot_taken',
        'at': '2026-11-19T12:00:00.000Z',
      });
      expect(await storedStatus('l-ana'), 'confirmed');
      expect(await storedStatus('l-nikola'), 'rejected');
    });

    test("the lesson's own student may see it but not confirm it: 403", () async {
      final response = await post('/lessons/l-ana/confirmation', as: 'ana');

      expect(response.statusCode, 403);
      expect(bodyOf(response)['code'], 'not-allowed');
      expect(await storedStatus('l-ana'), 'pending');
    });

    test('anyone else gets 404, the same as for a lesson that does not exist', () async {
      for (final stranger in ['nikola', 'jovan', 'jovana']) {
        final response = await post('/lessons/l-ana/confirmation', as: stranger);

        expect(response.statusCode, 404, reason: stranger);
        expect(bodyOf(response)['code'], 'not-found');
      }
      final missing = await post('/lessons/no-such-lesson/confirmation', as: 'milica');
      expect(missing.statusCode, 404);
      expect(await storedStatus('l-ana'), 'pending');
    });

    test('confirming a lesson that is already confirmed is 409 invalid-transition, with both statuses', () async {
      await post('/lessons/l-ana/confirmation', as: 'milica');

      final response = await post('/lessons/l-ana/confirmation', as: 'milica');

      expect(response.statusCode, 409);
      final problem = bodyOf(response);
      expect(problem['code'], 'invalid-transition');
      expect((problem['from']! as Map<String, Object?>)['type'], 'confirmed');
      expect((problem['to']! as Map<String, Object?>)['type'], 'confirmed');
    });
  });

  test('the professor rejects a pending request', () async {
    await insertLesson(database, 'l-ana', slot: 's-1', student: 'ana');

    final response = await post('/lessons/l-ana/rejection', as: 'milica');

    expect(response.statusCode, 200);
    expect(statusOf(bodyOf(response)), {'type': 'rejected', 'cause': 'by_professor', 'at': '2026-11-19T12:00:00.000Z'});
    expect(await storedStatus('l-ana'), 'rejected');
  });

  group('held and no-show', () {
    setUp(
      () => insertLesson(
        database,
        'l-ana',
        slot: 's-1',
        student: 'ana',
        status: 'confirmed',
        statusAt: DateTime.utc(2026, 11, 18, 12),
      ),
    );

    test('a note over 500 characters is 422, with its length and the limit', () async {
      clock.current = duringS1;

      final response = await post('/lessons/l-ana/held', as: 'milica', body: {'note': 'x' * 501});

      expect(response.statusCode, 422);
      final problem = bodyOf(response);
      expect(problem['code'], 'note-too-long');
      expect(problem['value'], 501);
      expect(problem['max'], 500);
      expect(await storedStatus('l-ana'), 'confirmed');
    });

    test('before the lesson starts it is 409 lesson-not-started', () async {
      final response = await post('/lessons/l-ana/held', as: 'milica', body: {});

      expect(response.statusCode, 409);
      expect(bodyOf(response)['code'], 'lesson-not-started');
    });

    test('after the start the professor records it as held, with a note', () async {
      clock.current = duringS1;

      final response = await post('/lessons/l-ana/held', as: 'milica', body: {'note': 'Radili smo integrale.'});

      expect(response.statusCode, 200);
      expect(statusOf(bodyOf(response)), {
        'type': 'held',
        'at': '2026-12-01T10:30:00.000Z',
        'note': 'Radili smo integrale.',
      });
      expect(await storedStatus('l-ana'), 'held');
    });

    test('without a note the status has no note field', () async {
      clock.current = duringS1;

      final response = await post('/lessons/l-ana/held', as: 'milica', body: {});

      expect(response.statusCode, 200);
      expect(statusOf(bodyOf(response)), {'type': 'held', 'at': '2026-12-01T10:30:00.000Z'});
    });

    test('a note that is not a string is 400', () async {
      clock.current = duringS1;

      final response = await post('/lessons/l-ana/held', as: 'milica', body: {'note': 42});

      expect(response.statusCode, 400);
      expect(await storedStatus('l-ana'), 'confirmed');
    });

    test('after the start the professor records a no-show', () async {
      clock.current = duringS1;

      final response = await post('/lessons/l-ana/no-show', as: 'milica');

      expect(response.statusCode, 200);
      expect(statusOf(bodyOf(response)), {'type': 'no_show', 'at': '2026-12-01T10:30:00.000Z'});
      expect(await storedStatus('l-ana'), 'no_show');
    });
  });

  group('verifications', () {
    test('the admin sees the queue, the longest-waiting first, with the details', () async {
      final response = await get('/verifications', as: 'jovana');

      expect(response.statusCode, 200);
      final queue = (jsonDecode(response.body) as List<Object?>).cast<Map<String, Object?>>();
      expect([for (final profile in queue) profile['id']], ['vesna', 'jovan']);
      expect(verificationOf(queue.first), {
        'type': 'awaiting_review',
        'submittedAt': '2026-11-05T14:00:00.000Z',
        'diplomaFile': 'diplome/vesna.pdf',
        'linkedIn': 'https://www.linkedin.com/in/vesna',
      });
    });

    test('a professor may not see the queue: 403', () async {
      final response = await get('/verifications', as: 'milica');

      expect(response.statusCode, 403);
      expect(bodyOf(response)['code'], 'not-allowed');
    });

    test('the admin approves, and a second approval is 409 with the status it has now', () async {
      final approved = await post('/verifications/jovan/approval', as: 'jovana');

      expect(approved.statusCode, 200);
      expect(verificationOf(bodyOf(approved)), {'type': 'verified', 'by': 'jovana', 'at': '2026-11-19T12:00:00.000Z'});
      expect(await storedVerification('jovan'), 'verified');

      final again = await post('/verifications/jovan/approval', as: 'jovana');

      expect(again.statusCode, 409);
      final problem = bodyOf(again);
      expect(problem['code'], 'invalid-verification-transition');
      expect((problem['from']! as Map<String, Object?>)['type'], 'verified');
    });

    test('a professor may not approve: 403, and nothing changes', () async {
      final response = await post('/verifications/jovan/approval', as: 'milica');

      expect(response.statusCode, 403);
      expect(await storedVerification('jovan'), 'awaiting_review');
    });

    test('a professor who does not exist is 404', () async {
      final response = await post('/verifications/nobody/approval', as: 'jovana');

      expect(response.statusCode, 404);
    });

    test('a reason under 10 characters is 422, with its length and the minimum', () async {
      final response = await post('/verifications/jovan/rejection', as: 'jovana', body: {'reason': 'Loše'});

      expect(response.statusCode, 422);
      final problem = bodyOf(response);
      expect(problem['code'], 'rejection-reason-too-short');
      expect(problem['value'], 4);
      expect(problem['min'], 10);
      expect(await storedVerification('jovan'), 'awaiting_review');
    });

    test('the admin rejects with a reason', () async {
      final response = await post(
        '/verifications/jovan/rejection',
        as: 'jovana',
        body: {'reason': 'Diploma nije čitljiva.'},
      );

      expect(response.statusCode, 200);
      expect(verificationOf(bodyOf(response)), {
        'type': 'rejected',
        'by': 'jovana',
        'at': '2026-11-19T12:00:00.000Z',
        'reason': 'Diploma nije čitljiva.',
      });
      expect(await storedVerification('jovan'), 'rejected');
    });
  });
}
