import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:http/http.dart' as http;
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';

import 'support/mail.dart';
import 'support/unused.dart';

const backoffice = 'http://localhost:8081';
const stranger = 'http://evil.example';

late RelicServer server;
late Uri base;

Uri at(String path) => base.replace(path: path);

void main() {
  setUpAll(() async {
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      buildHandler(
        corsOrigins: const [backoffice],
        lessons: UnusedLessons(),
        professors: UnusedProfessors(),
        verifications: UnusedVerifications(),
        sessions: testSessions(),
        notifications: testNotifications(),
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() => server.close());

  test('health answers ok', () async {
    final response = await http.get(at(ApiPaths.health));

    expect(response.statusCode, 200);
    expect(response.body, 'ok');
  });

  test('an unknown path is a not-found problem', () async {
    final response = await http.get(at('/no-such-route'));

    expect(response.statusCode, 404);
    expect(response.headers['content-type'], startsWith(ProblemDto.mediaType));
    final problem = ProblemDto.fromJson(jsonDecode(response.body) as Map<String, Object?>);
    expect(problem.code, ErrorCodes.notFound);
  });

  test('a known path with the wrong method is 405 and says which methods exist', () async {
    final response = await http.post(at(ApiPaths.health));

    expect(response.statusCode, 405);
    expect(response.headers['allow'], contains('GET'));
  });

  group('CORS', () {
    Future<http.Response> preflight(String origin) async {
      final request = http.Request('OPTIONS', at(ApiPaths.health))
        ..headers['Origin'] = origin
        ..headers['Access-Control-Request-Method'] = 'POST';
      return http.Response.fromStream(await http.Client().send(request));
    }

    test('the preflight from the backoffice is allowed, with credentials', () async {
      final response = await preflight(backoffice);

      expect(response.statusCode, 204);
      expect(response.headers['access-control-allow-origin'], backoffice);
      expect(response.headers['access-control-allow-credentials'], 'true');
      expect(response.headers['access-control-allow-methods'], contains('POST'));
    });

    test('the preflight from another site gets no permission', () async {
      final response = await preflight(stranger);

      expect(response.statusCode, 204);
      expect(response.headers, isNot(contains('access-control-allow-origin')));
      expect(response.headers['vary'], 'Origin');
    });

    test('a GET from another site runs, but the browser is not allowed to read it', () async {
      final response = await http.get(at(ApiPaths.health), headers: {'Origin': stranger});

      expect(response.statusCode, 200);
      expect(response.headers, isNot(contains('access-control-allow-origin')));
    });

    test('a POST from another site is refused before it reaches a handler', () async {
      final response = await http.post(at(ApiPaths.health), headers: {'Origin': stranger});

      expect(response.statusCode, 403);
    });

    test('a GET from the backoffice carries the allow headers', () async {
      final response = await http.get(at(ApiPaths.health), headers: {'Origin': backoffice});

      expect(response.statusCode, 200);
      expect(response.headers['access-control-allow-origin'], backoffice);
    });
  });
}
