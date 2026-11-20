import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  late InMemorySessionRepository sessions;
  late SessionBloc session;

  setUp(() {
    sessions = InMemorySessionRepository({
      'profesor1': ('casovi-demo', professor),
      'ucenik1': ('casovi-demo', student),
    });
    session = SessionBloc(
      restoreSession: RestoreSession(sessions),
      logOut: LogOut(sessions),
      admits: AccessPolicy.canUseBackoffice,
      expirations: sessions.expirations,
    );
  });

  tearDown(() => session.close());

  LoginFormBloc buildBloc() => LoginFormBloc(LogIn(sessions), session);

  blocTest<LoginFormBloc, LoginFormState>(
    'the right password hands the user to the session',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoginSubmitted(login: 'profesor1', password: 'casovi-demo')),
    expect: () => [const LoginSubmitting(), const LoginIdle()],
    verify: (_) async {
      await pumpEventQueue();
      expect(session.state, const SignedIn(professor));
    },
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'a wrong password is rejected and nobody signs in',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoginSubmitted(login: 'profesor1', password: 'pogresna')),
    expect: () => [const LoginSubmitting(), const LoginRejected()],
    verify: (_) async {
      await pumpEventQueue();
      expect(session.state, const SessionUnknown());
      expect(sessions.signedIn, isNull);
    },
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'a server that does not answer fails with the kind of failure',
    setUp: () => sessions.fail = true,
    build: buildBloc,
    act: (bloc) => bloc.add(const LoginSubmitted(login: 'profesor1', password: 'casovi-demo')),
    expect: () => [const LoginSubmitting(), const LoginFailed(RepositoryFailure.unreachable)],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'a student in the backoffice is signed out with the reason',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoginSubmitted(login: 'ucenik1', password: 'casovi-demo')),
    expect: () => [const LoginSubmitting(), const LoginIdle()],
    verify: (_) async {
      await pumpEventQueue();
      expect(session.state, const SignedOut(reason: SignOutReason.roleNotAllowed));
      expect(sessions.signedIn, isNull);
    },
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'a second submit while the first is running is ignored',
    setUp: () => sessions.gate = Completer<void>(),
    build: buildBloc,
    act: (bloc) async {
      const submit = LoginSubmitted(login: 'profesor1', password: 'casovi-demo');
      bloc
        ..add(submit)
        ..add(submit);
      await pumpEventQueue();
      sessions.gate!.complete();
    },
    expect: () => [const LoginSubmitting(), const LoginIdle()],
    verify: (_) => expect(sessions.logInCalls, 1),
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'after a rejection the next try can succeed',
    build: buildBloc,
    seed: () => const LoginRejected(),
    act: (bloc) => bloc.add(const LoginSubmitted(login: 'profesor1', password: 'casovi-demo')),
    expect: () => [const LoginSubmitting(), const LoginIdle()],
  );
}
