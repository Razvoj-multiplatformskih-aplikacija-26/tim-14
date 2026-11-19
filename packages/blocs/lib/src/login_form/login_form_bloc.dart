import 'package:bloc/bloc.dart';
import 'package:use_cases/use_cases.dart';

import '../session/session_bloc.dart';
import '../session/session_event.dart';
import 'login_form_event.dart';
import 'login_form_state.dart';

// Samo forma za prijavu. Ko sme u aplikaciju odlučuje SessionBloc, kome se predaje prijavljeni korisnik.
class LoginFormBloc extends Bloc<LoginFormEvent, LoginFormState> {
  LoginFormBloc(this._logIn, this._session) : super(const LoginIdle()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  final LogIn _logIn;
  final SessionBloc _session;

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginFormState> emit) async {
    // Drugi Enter dok prva prijava još traje ne šalje još jedan zahtev.
    if (state is LoginSubmitting) {
      return;
    }

    emit(const LoginSubmitting());
    try {
      final user = await _logIn(login: event.login, password: event.password);
      if (user == null) {
        emit(const LoginRejected());
        return;
      }
      _session.add(SessionStarted(user));
      emit(const LoginIdle());
    } on RepositoryException catch (e) {
      emit(LoginFailed(e.failure));
    }
  }
}
