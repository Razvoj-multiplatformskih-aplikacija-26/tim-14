import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

final base = Uri.parse('http://localhost:8080');

http.Response problemAnswer(ProblemDto problem) =>
    http.Response(jsonEncode(problem.toJson()), problem.status, headers: {'content-type': ProblemDto.mediaType});

http.Response jsonAnswer(Object? json, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(json)), status, headers: {'content-type': 'application/json'});

ApiClient clientOver(
  MockClient server, {
  TokenStore? tokens,
  bool cookie = false,
  Duration timeout = const Duration(seconds: 10),
}) => ApiClient(baseUri: base, tokens: tokens, httpClient: server, keepsSessionInCookie: cookie, timeout: timeout);

Matcher failsWith(RepositoryFailure failure) =>
    throwsA(isA<RepositoryException>().having((error) => error.failure, 'failure', failure));

void main() {
  group('ApiClient', () {
    test('sends the stored token as Bearer, and JSON as JSON', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('token-of-ana');
      late http.Request seen;
      final api = clientOver(
        MockClient((request) async {
          seen = request;
          return jsonAnswer({'ok': true});
        }),
        tokens: tokens,
      );

      final answer = await api.post(ApiPaths.lessons, body: {'slotId': 's-1'});

      expect(answer, isA<ApiAccepted>());
      expect(seen.headers['Authorization'], 'Bearer token-of-ana');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), {'slotId': 's-1'});
    });

    test('in the browser it sends no token: the cookie carries the session', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('token-of-ana');
      late http.Request seen;
      final api = clientOver(
        MockClient((request) async {
          seen = request;
          return jsonAnswer(const <Object?>[]);
        }),
        tokens: tokens,
        cookie: true,
      );

      await api.get(ApiPaths.lessons);

      expect(seen.headers, isNot(contains('Authorization')));
    });

    test('a domain rule from the server comes back as the same DomainError, limit included', () async {
      final api = clientOver(
        MockClient((request) async => problemAnswer(const TooManyPendingRequests(max: 2).toProblem())),
      );

      final answer = await api.post(ApiPaths.lessons);

      expect(answer, isA<ApiRejected>().having((a) => a.error, 'error', const TooManyPendingRequests(max: 2)));
    });

    test('a code this app does not know is refused, not a crash: an older app meets a newer server', () async {
      final api = clientOver(
        MockClient(
          (request) async =>
              problemAnswer(const ProblemDto(status: 409, code: 'lesson-limit-per-day', title: '', max: 5)),
        ),
      );

      final answer = await api.post(ApiPaths.lessons);

      expect(answer, isA<ApiRefused>());
      expect(() => resultOf(answer, (json) => json), failsWith(RepositoryFailure.refused));
    });

    test('a server that cannot be reached is unreachable', () async {
      final api = clientOver(MockClient((request) async => throw http.ClientException('Connection refused')));

      expect(api.get(ApiPaths.professors), failsWith(RepositoryFailure.unreachable));
    });

    test('a server that does not answer in time is unreachable too, so no screen loads forever', () async {
      final never = Completer<http.Response>();
      final api = clientOver(MockClient((request) => never.future), timeout: const Duration(milliseconds: 50));

      expect(api.get(ApiPaths.professors), failsWith(RepositoryFailure.unreachable));
    });

    test('an expired session fires expirations and fails with sessionExpired', () async {
      final api = clientOver(
        MockClient(
          (request) async =>
              problemAnswer(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Expired')),
        ),
      );
      final expired = api.expirations.first;

      await expectLater(api.get(ApiPaths.lessons), failsWith(RepositoryFailure.sessionExpired));
      await expired;
    });

    test('a 5xx and an answer that is not JSON are server errors', () async {
      final down = clientOver(MockClient((request) async => http.Response('', 503)));
      final garbage = clientOver(MockClient((request) async => http.Response('<html>', 200)));

      expect(down.get(ApiPaths.professors), failsWith(RepositoryFailure.serverError));
      expect(garbage.get(ApiPaths.professors), failsWith(RepositoryFailure.serverError));
    });

    test('a read that the domain refuses is a server error, not a crash', () async {
      final api = clientOver(MockClient((request) async => jsonAnswer({'role': 'janitor'})));
      final answer = await api.get(ApiPaths.currentSession);

      expect(
        () => accepted(answer, (json) => UserDto.fromJson(object(json)).toDomain()),
        failsWith(RepositoryFailure.serverError),
      );
    });
  });

  group('HttpSessionRepository', () {
    final session = SessionDto(
      user: const UserDto(id: 'ana-markovic', name: 'Ana Marković', role: 'student'),
      expiresAt: DateTime.utc(2026, 11, 21, 18),
      token: 'signed-token',
    );

    test('logging in sends the login, keeps the token and returns the user', () async {
      final tokens = MemoryTokenStore();
      late Map<String, Object?> sent;
      final sessions = HttpSessionRepository(
        clientOver(
          MockClient((request) async {
            expect(request.url.path, ApiPaths.sessions);
            sent = jsonDecode(request.body) as Map<String, Object?>;
            return jsonAnswer(session.toJson(), status: 201);
          }),
          tokens: tokens,
        ),
      );

      final user = await sessions.logIn(login: 'ucenik1', password: 'casovi-demo');

      expect(user, const User(id: UserId('ana-markovic'), name: 'Ana Marković', role: Role.student));
      expect(sent, {'login': 'ucenik1', 'password': 'casovi-demo', 'cookie': false});
      expect(await tokens.read(), 'signed-token');
    });

    test('a wrong password is null, and nothing is stored', () async {
      final tokens = MemoryTokenStore();
      final sessions = HttpSessionRepository(
        clientOver(
          MockClient(
            (request) async =>
                problemAnswer(const ProblemDto(status: 401, code: ErrorCodes.invalidCredentials, title: 'Wrong')),
          ),
          tokens: tokens,
        ),
      );

      expect(await sessions.logIn(login: 'ucenik1', password: 'x'), isNull);
      expect(await tokens.read(), isNull);
    });

    test('in the browser the login asks for the cookie', () async {
      late Map<String, Object?> sent;
      final sessions = HttpSessionRepository(
        clientOver(
          MockClient((request) async {
            sent = jsonDecode(request.body) as Map<String, Object?>;
            return jsonAnswer(SessionDto(user: session.user, expiresAt: session.expiresAt).toJson(), status: 201);
          }),
          cookie: true,
        ),
      );

      await sessions.logIn(login: 'profesor1', password: 'casovi-demo');

      expect(sent['cookie'], isTrue);
    });

    test('restoring without a stored token does not even ask the server', () async {
      final sessions = HttpSessionRepository(
        clientOver(MockClient((request) async => fail('the server should not be called'))),
      );

      expect(await sessions.current(), isNull);
    });

    test('restoring with a token gives the user; an expired one is cleared and gives null', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('signed-token');
      var expired = false;
      final sessions = HttpSessionRepository(
        clientOver(
          MockClient(
            (request) async => expired
                ? problemAnswer(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Expired'))
                : jsonAnswer(SessionDto(user: session.user, expiresAt: session.expiresAt).toJson()),
          ),
          tokens: tokens,
        ),
      );

      expect((await sessions.current())?.name, 'Ana Marković');

      expired = true;
      expect(await sessions.current(), isNull);
      expect(await tokens.read(), isNull);
    });

    test('logging out clears the token even when the server cannot be reached', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('signed-token');
      final sessions = HttpSessionRepository(
        clientOver(MockClient((request) async => throw http.ClientException('down')), tokens: tokens),
      );

      await expectLater(sessions.logOut(), failsWith(RepositoryFailure.unreachable));
      expect(await tokens.read(), isNull);
    });
  });
}
