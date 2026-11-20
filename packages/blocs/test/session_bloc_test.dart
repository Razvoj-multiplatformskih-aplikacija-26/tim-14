import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  late InMemorySessionRepository sessions;

  setUp(() => sessions = InMemorySessionRepository({'profesor1': ('casovi-demo', professor)}));

  SessionBloc buildBloc() => SessionBloc(
    restoreSession: RestoreSession(sessions),
    logOut: LogOut(sessions),
    admits: AccessPolicy.canUseBackoffice,
    expirations: sessions.expirations,
  );

  test('starts as unknown', () {
    expect(buildBloc().state, const SessionUnknown());
  });

  blocTest<SessionBloc, SessionState>(
    'a remembered session survives a restart',
    setUp: () => sessions.signedIn = professor,
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedIn(professor)],
  );

  blocTest<SessionBloc, SessionState>(
    'no remembered session is signed out without a reason',
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut()],
  );

  blocTest<SessionBloc, SessionState>(
    'a server that does not answer on start is signed out as unreachable',
    setUp: () => sessions.fail = true,
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.unreachable)],
  );

  blocTest<SessionBloc, SessionState>(
    'an expired session signs out with the reason',
    setUp: () => sessions.signedIn = professor,
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await Future<void>.delayed(Duration.zero);
      sessions.expire();
    },
    expect: () => [const SignedIn(professor), const SignedOut(reason: SignOutReason.expired)],
  );

  blocTest<SessionBloc, SessionState>(
    'an expiration while signed out changes nothing',
    build: buildBloc,
    seed: () => const SignedOut(reason: SignOutReason.loggedOut),
    act: (bloc) => sessions.expire(),
    expect: () => <SessionState>[],
  );

  blocTest<SessionBloc, SessionState>(
    'a student restored in the backoffice is refused and logged out',
    setUp: () => sessions.signedIn = student,
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.roleNotAllowed)],
    verify: (_) {
      expect(sessions.signedIn, isNull);
      expect(sessions.logOutCalls, 1);
    },
  );

  blocTest<SessionBloc, SessionState>(
    'a started session for an allowed role signs in',
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionStarted(admin)),
    expect: () => [const SignedIn(admin)],
  );

  blocTest<SessionBloc, SessionState>(
    'logging out ends the session',
    setUp: () => sessions.signedIn = professor,
    build: buildBloc,
    seed: () => const SignedIn(professor),
    act: (bloc) => bloc.add(const SessionLogOutRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.loggedOut)],
    verify: (_) => expect(sessions.signedIn, isNull),
  );

  blocTest<SessionBloc, SessionState>(
    'logging out still signs out when the server does not answer',
    setUp: () => sessions.fail = true,
    build: buildBloc,
    seed: () => const SignedIn(professor),
    act: (bloc) => bloc.add(const SessionLogOutRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.loggedOut)],
    errors: () => [isA<RepositoryException>()],
  );
}
