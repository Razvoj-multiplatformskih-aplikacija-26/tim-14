import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:relic/relic.dart' hide Result;
import 'package:server/server.dart';
import 'package:server/src/http.dart' show handleErrors;
import 'package:test/test.dart';

import 'support/unused.dart';

/// Accounts in memory, so the login is tested without a database.
final class MemoryAccounts implements AccountStore {
  MemoryAccounts(this.accounts);

  final Map<String, Account> accounts;

  @override
  Future<Account?> account(String login) async => accounts[login];
}

const ana = User(id: UserId('ana-markovic'), name: 'Ana Marković', role: Role.student);
const password = 'casovi-demo';

void main() {
  late RelicServer server;
  late Uri base;
  late SessionHandlers sessions;

  setUpAll(() async {
    sessions = testSessions(
      accounts: MemoryAccounts({'ucenik1': Account(user: ana, passwordHash: await hashPassword(password))}),
    );
    // The session routes of the server, plus one route behind each middleware, to see what reaches a handler.
    final router = RelicRouter()
      ..post(ApiPaths.sessions, sessions.logIn)
      ..get(ApiPaths.currentSession, sessions.current)
      ..delete(ApiPaths.currentSession, sessions.logOut)
      ..get('/private', (request) => Response.ok(body: Body.fromString(currentUser(request).name)))
      ..get('/public', (request) => Response.ok(body: Body.fromString(optionalUser(request)?.name ?? 'posetilac')))
      ..use(ApiPaths.currentSession, sessions.signedIn)
      ..use('/private', sessions.signedIn)
      ..use('/public', sessions.optionallySignedIn);
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(const Pipeline().addMiddleware(handleErrors()).addHandler(router.asHandler));
    base = Uri.parse('http://localhost:${server.port}');
  });
  tearDownAll(() => server.close());

  Uri at(String path) => base.replace(path: path);

  Future<http.Response> logIn(String login, String password, {bool cookie = false}) => http.post(
    at(ApiPaths.sessions),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(LoginDto(login: login, password: password, cookie: cookie).toJson()),
  );

  Map<String, String> bearer(String token) => {'Authorization': 'Bearer $token'};

  String codeOf(http.Response response) => (jsonDecode(response.body) as Map<String, Object?>)['code']! as String;

  group('logging in', () {
    test('the right password gives 201, the user and a token for the app', () async {
      final response = await logIn('ucenik1', password);

      expect(response.statusCode, 201);
      final session = SessionDto.fromJson(jsonDecode(response.body) as Map<String, Object?>);
      expect(session.user.id, ana.id.value);
      expect(session.user.role, 'student');
      expect(session.token, isNotNull);
      expect(session.expiresAt.difference(DateTime.now().toUtc()).inHours, closeTo(8, 1));
      expect(response.headers, isNot(contains('set-cookie')));
    });

    test('a wrong password and an unknown login get the same 401 invalid-credentials', () async {
      final wrongPassword = await logIn('ucenik1', 'nije-lozinka');
      final unknownLogin = await logIn('nema-ga', password);

      for (final response in [wrongPassword, unknownLogin]) {
        expect(response.statusCode, 401);
        expect(codeOf(response), ErrorCodes.invalidCredentials);
        expect(response.headers['www-authenticate'], 'Bearer');
      }
    });

    test('a body without a password is 400', () async {
      final response = await http.post(
        at(ApiPaths.sessions),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': 'ucenik1'}),
      );

      expect(response.statusCode, 400);
      expect(codeOf(response), ErrorCodes.badRequest);
    });

    test('the browser gets an HttpOnly cookie and no token in the body', () async {
      final response = await logIn('ucenik1', password, cookie: true);

      expect(response.statusCode, 201);
      expect(SessionDto.fromJson(jsonDecode(response.body) as Map<String, Object?>).token, isNull);
      final cookie = response.headers['set-cookie']!;
      expect(cookie, startsWith('${ApiCookies.session}='));
      expect(cookie.toLowerCase(), contains('httponly'));
      expect(cookie.toLowerCase(), contains('samesite=lax'));
    });
  });

  group('the token on later calls', () {
    test('restores who is signed in', () async {
      final token = SessionDto.fromJson(jsonDecode((await logIn('ucenik1', password)).body) as Map<String, Object?>)
          .token!;

      final response = await http.get(at(ApiPaths.currentSession), headers: bearer(token));

      expect(response.statusCode, 200);
      final session = SessionDto.fromJson(jsonDecode(response.body) as Map<String, Object?>);
      expect(session.user.name, 'Ana Marković');
      expect(session.token, isNull);
    });

    test('the cookie works in place of the header', () async {
      final cookie = (await logIn('ucenik1', password, cookie: true)).headers['set-cookie']!.split(';').first;

      final response = await http.get(at('/private'), headers: {'Cookie': cookie});

      expect(response.statusCode, 200);
      expect(response.body, 'Ana Marković');
    });

    test('without a token it is 401 sign-in-required', () async {
      final response = await http.get(at('/private'));

      expect(response.statusCode, 401);
      expect(codeOf(response), ErrorCodes.signInRequired);
    });

    test('an expired token is 401 session-expired', () async {
      final expired = testSessions(ttl: const Duration(minutes: -1)).issue(ana);

      final response = await http.get(at('/private'), headers: bearer(expired));

      expect(response.statusCode, 401);
      expect(codeOf(response), ErrorCodes.sessionExpired);
    });

    test('a token signed with another secret, or with no signature at all, is 401 session-expired', () async {
      final otherSecret = SessionHandlers(
        accounts: MemoryAccounts(const {}),
        secret: 'another-secret-0123456789abcdef0123456789',
        ttl: const Duration(hours: 1),
      ).issue(ana);
      final unsigned = JWT({
        'name': ana.name,
        'role': 'admin',
      }, subject: ana.id.value).sign(SecretKey(''), algorithm: JWTAlgorithm.HS256);
      final noneAlgorithm =
          '${base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'))}.'
          '${base64Url.encode(utf8.encode('{"sub":"ana-markovic","name":"Ana","role":"admin","exp":9999999999}'))}.';

      for (final token in [otherSecret, unsigned, noneAlgorithm, 'not-a-token']) {
        final response = await http.get(at('/private'), headers: bearer(token));
        expect(response.statusCode, 401, reason: token);
        expect(codeOf(response), ErrorCodes.sessionExpired, reason: token);
      }
    });

    test('the role comes from the token the server signed, not from anything the client says', () async {
      final token = sessions.issue(ana);
      final payload = JWT.verify(token, SecretKey(testSecret)).payload as Map<String, Object?>;

      expect(payload['sub'], ana.id.value);
      expect(payload['role'], 'student');
      expect(payload['exp'], isA<int>());
    });
  });

  group('a public route', () {
    test('lets a visitor in without a session', () async {
      final response = await http.get(at('/public'));

      expect(response.statusCode, 200);
      expect(response.body, 'posetilac');
    });

    test('knows a signed-in caller, and treats a bad token like no token', () async {
      final signedIn = await http.get(at('/public'), headers: bearer(sessions.issue(ana)));
      final badToken = await http.get(at('/public'), headers: bearer('not-a-token'));

      expect(signedIn.body, 'Ana Marković');
      expect(badToken.statusCode, 200);
      expect(badToken.body, 'posetilac');
    });
  });

  test('logging out is 204 and clears the cookie', () async {
    final response = await http.delete(at(ApiPaths.currentSession), headers: bearer(sessions.issue(ana)));

    expect(response.statusCode, 204);
    final cookie = response.headers['set-cookie']!.toLowerCase();
    expect(cookie, startsWith('${ApiCookies.session}=;'));
    expect(cookie, contains('max-age=0'));
  });
}
