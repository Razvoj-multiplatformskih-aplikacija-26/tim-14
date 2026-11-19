import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// Ports for tests that never reach a repository, such as health and CORS. A call means the test is wrong, so
/// every member throws. `noSuchMethod` answers each member of the interface without writing them out, much like
/// a Mockito mock with no stubs.
final class UnusedLessons implements LessonRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw StateError('This test does not use lessons');
}

final class UnusedVerifications implements VerificationRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw StateError('This test does not use verifications');
}

Future<User?> noUsers(UserId id) async => null;
