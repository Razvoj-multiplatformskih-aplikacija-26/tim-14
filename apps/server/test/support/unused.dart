import 'package:server/server.dart';
import 'package:use_cases/use_cases.dart';

/// Ports for tests that never reach a repository, such as health and CORS. A call means the test is wrong, so
/// every member throws. `noSuchMethod` answers each member of the interface without writing them out, much like
/// a Mockito mock with no stubs.
final class UnusedLessons implements LessonRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw StateError('This test does not use lessons');
}

final class UnusedProfessors implements ProfessorRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw StateError('This test does not use professors');
}

final class UnusedVerifications implements VerificationRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw StateError('This test does not use verifications');
}

/// A secret only the tests use, as long as `JWT_SECRET` must be.
const testSecret = 'test-only-secret-0123456789abcdef0123456789';

/// The login of the server, with a test secret and [accounts] (none by default).
SessionHandlers testSessions({AccountStore accounts = const _NoAccounts(), Duration ttl = const Duration(hours: 8)}) =>
    SessionHandlers(accounts: accounts, secret: testSecret, ttl: ttl);

final class _NoAccounts implements AccountStore {
  const _NoAccounts();

  @override
  Future<Account?> account(String login) async => null;
}
