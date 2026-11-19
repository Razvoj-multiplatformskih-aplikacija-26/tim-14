import 'dart:io';

import 'package:server/server.dart';
import 'package:test/test.dart';

const minimal = {
  'DATABASE_URL': 'postgres://casovi:casovi@localhost:5436/casovi?sslmode=disable',
  'JWT_SECRET': 'dev-only-secret-change-me-0123456789abcdef',
  'LINKEDIN_API_KEY': 'fake-dev-key',
};

void main() {
  test('only the secrets are required; the rest has local defaults', () {
    final config = ServerConfig.fromEnvironment(minimal);

    expect(config.host, '127.0.0.1');
    expect(config.port, 8080);
    expect(config.corsOrigins, ['http://localhost:8081']);
    expect(config.sessionTtl, const Duration(minutes: 480));
    expect(config.secureCookie, isFalse);
    expect(config.demoPassword, isNull);
    expect(config.linkedInApiKey, 'fake-dev-key');
  });

  test('values from the environment win over the defaults', () {
    final config = ServerConfig.fromEnvironment({
      ...minimal,
      'HOST': '0.0.0.0',
      'PORT': '9090',
      'CORS_ORIGINS': 'http://localhost:8081, ,https://casovi.example,',
      'SESSION_TTL_MINUTES': '15',
      'COOKIE_SECURE': 'true',
      'DEMO_PASSWORD': 'casovi-demo',
    });

    expect(config.host, '0.0.0.0');
    expect(config.port, 9090);
    expect(config.corsOrigins, ['http://localhost:8081', 'https://casovi.example']);
    expect(config.sessionTtl, const Duration(minutes: 15));
    expect(config.secureCookie, isTrue);
    expect(config.demoPassword, 'casovi-demo');
  });

  for (final name in minimal.keys) {
    test('a missing $name stops the server at startup', () {
      expect(
        () => ServerConfig.fromEnvironment({...minimal}..remove(name)),
        throwsA(isA<StateError>().having((error) => error.message, 'message', contains(name))),
      );
    });
  }

  test('a JWT secret under 32 bytes is refused', () {
    expect(
      () => ServerConfig.fromEnvironment({...minimal, 'JWT_SECRET': 'short'}),
      throwsA(isA<StateError>().having((error) => error.message, 'message', contains('32 bytes'))),
    );
  });

  test('the .env reader skips comments and strips quotes', () {
    final directory = Directory.systemTemp.createTempSync('env_file_test');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/.env')
      ..writeAsStringSync('''
# PORT=1234 in a comment
POSTGRES_USER=casovi
  # HOST=0.0.0.0 in an indented comment
JWT_SECRET="with spaces and = inside"
DEMO_PASSWORD='single'
DATABASE_URL=postgres://u:p@localhost:5436/db?sslmode=disable
NOT_A_PAIR
=no-name
''');

    expect(readEnvFile(file), {
      'POSTGRES_USER': 'casovi',
      'JWT_SECRET': 'with spaces and = inside',
      'DEMO_PASSWORD': 'single',
      'DATABASE_URL': 'postgres://u:p@localhost:5436/db?sslmode=disable',
    });
  });

  test('a missing .env file reads as empty', () {
    expect(readEnvFile(File('${Directory.systemTemp.path}/does-not-exist/.env')), isEmpty);
  });
}
