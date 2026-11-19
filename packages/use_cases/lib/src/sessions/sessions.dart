import 'package:domain/domain.dart';

import '../ports/session_repository.dart';

// Prijava vraća null kada login ili lozinka nisu tačni. Razmak oko logina se briše, oko lozinke ne.
final class LogIn {
  LogIn(this._sessions);

  final SessionRepository _sessions;

  Future<User?> call({required String login, required String password}) =>
      _sessions.logIn(login: login.trim(), password: password);
}

// Na pokretanju aplikacije: ko je već prijavljen, ako sesija još važi.
final class RestoreSession {
  RestoreSession(this._sessions);

  final SessionRepository _sessions;

  Future<User?> call() => _sessions.current();
}

final class LogOut {
  LogOut(this._sessions);

  final SessionRepository _sessions;

  Future<void> call() => _sessions.logOut();
}
