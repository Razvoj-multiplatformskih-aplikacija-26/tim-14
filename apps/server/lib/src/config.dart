import 'dart:convert';

final class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.databaseUrl,
    required this.corsOrigins,
    this.sessionTtl = const Duration(hours: 8),
    this.secureCookie = false,
    this.demoPassword,
    required this.jwtSecret,
    this.resendApiKey,
    this.mailTo,
    this.mailFrom = defaultMailFrom,
  });

  factory ServerConfig.fromEnvironment(Map<String, String> environment) => ServerConfig(
    host: environment['HOST'] ?? '127.0.0.1',
    port: int.parse(environment['PORT'] ?? '8080'),
    databaseUrl: environment['DATABASE_URL'] ?? (throw _missing('DATABASE_URL')),
    corsOrigins: [
      for (final origin in (environment['CORS_ORIGINS'] ?? 'http://localhost:8081').split(','))
        if (origin.trim().isNotEmpty) origin.trim(),
    ],
    sessionTtl: Duration(minutes: int.parse(environment['SESSION_TTL_MINUTES'] ?? '480')),
    secureCookie: environment['COOKIE_SECURE'] == 'true',
    demoPassword: environment['DEMO_PASSWORD'],
    jwtSecret: _jwtSecret(environment['JWT_SECRET']),
    resendApiKey: _resendApiKey(environment),
    mailTo: _set(environment['MAIL_TO']),
    mailFrom: _set(environment['MAIL_FROM']) ?? defaultMailFrom,
  );

  /// Resend's test sender, which needs no verified domain.
  static const defaultMailFrom = 'Casovi <onboarding@resend.dev>';

  final String host;
  final int port;
  final String databaseUrl;
  final List<String> corsOrigins;
  final Duration sessionTtl;
  final bool secureCookie;
  final String? demoPassword;
  final String jwtSecret;

  /// Null means the emails only go to the log (`LogMailer`). Compose passes an empty string when `.env` has none.
  final String? resendApiKey;

  /// The one inbox every email goes to. Required once there is a key.
  final String? mailTo;
  final String mailFrom;
}

StateError _missing(String name) => StateError('$name is not set. Copy .env.example to .env in the repository root.');

/// An empty value counts as not set, the way Compose passes a variable `.env` leaves empty.
String? _set(String? value) => (value == null || value.trim().isEmpty) ? null : value.trim();

String? _resendApiKey(Map<String, String> environment) {
  final key = _set(environment['RESEND_API_KEY']);
  if (key != null && _set(environment['MAIL_TO']) == null) {
    throw StateError('MAIL_TO must be set when RESEND_API_KEY is: the address the Resend account was opened with.');
  }
  return key;
}

String _jwtSecret(String? secret) => switch (secret) {
  null => throw _missing('JWT_SECRET'),
  final secret when utf8.encode(secret).length < 32 => throw StateError('JWT_SECRET must have at least 32 bytes.'),
  final secret => secret,
};
