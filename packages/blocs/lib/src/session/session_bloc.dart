import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'session_event.dart';
import 'session_state.dart';

// Ko je prijavljen u aplikaciji. Jedan za celu aplikaciju, iznad rutera.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  // Imenovani parametri sa _ : polje je privatno, a pozivalac piše ime bez crte (restoreSession: …).
  SessionBloc({
    required this._restoreSession,
    required this._logOut,
    required this._admits,
    required Stream<void> expirations,
  }) : super(const SessionUnknown()) {
    on<SessionRestoreRequested>(_onRestoreRequested);
    on<SessionStarted>(_onStarted);
    on<SessionLogOutRequested>(_onLogOutRequested);
    on<SessionExpired>(_onExpired);
    _expirations = expirations.listen((_) => add(const SessionExpired()));
  }

  final RestoreSession _restoreSession;
  final LogOut _logOut;

  // Koje uloge smeju u ovu aplikaciju. Pravilo daje aplikacija (backoffice: profesor i administrator).
  final bool Function(User user) _admits;

  late final StreamSubscription<void> _expirations;

  Future<void> _onRestoreRequested(SessionRestoreRequested event, Emitter<SessionState> emit) async {
    try {
      final user = await _restoreSession();
      if (user == null) {
        emit(const SignedOut());
        return;
      }
      await _start(user, emit);
    } on RepositoryException {
      emit(const SignedOut(reason: SignOutReason.unreachable));
    }
  }

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) async {
    await _start(event.user, emit);
  }

  // Zajedničko za povratak sesije i novu prijavu: uloga koja ne sme u aplikaciju se odmah odjavljuje,
  // da na serveru i u skladištu tokena ne ostane sesija koju niko ne koristi.
  Future<void> _start(User user, Emitter<SessionState> emit) async {
    if (_admits(user)) {
      emit(SignedIn(user));
      return;
    }
    await _logOutQuietly();
    emit(const SignedOut(reason: SignOutReason.roleNotAllowed));
  }

  Future<void> _onLogOutRequested(SessionLogOutRequested event, Emitter<SessionState> emit) async {
    await _logOutQuietly();
    emit(const SignedOut(reason: SignOutReason.loggedOut));
  }

  // Isticanje važi samo za prijavljenog. Ako je korisnik već odjavljen, nema šta da se promeni.
  void _onExpired(SessionExpired event, Emitter<SessionState> emit) {
    if (state is SignedIn) {
      emit(const SignedOut(reason: SignOutReason.expired));
    }
  }

  // Odjava lokalno uspeva i kad server ne odgovori, pa greška ide samo u addError (BlocObserver je vidi).
  Future<void> _logOutQuietly() async {
    try {
      await _logOut();
    } on RepositoryException catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  @override
  Future<void> close() async {
    await _expirations.cancel();
    return super.close();
  }
}
