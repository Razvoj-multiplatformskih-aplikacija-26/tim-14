import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

// Stanje ne pamti ni login ni lozinku: oba ostaju u poljima ekrana, pa ih BlocObserver nikad ne ispiše.
sealed class LoginFormState extends Equatable {
  const LoginFormState();

  @override
  List<Object?> get props => [];
}

// Forma čeka unos. U ovo stanje se vraća i posle uspešne prijave, dalje vodi SessionBloc.
class LoginIdle extends LoginFormState {
  const LoginIdle();
}

class LoginSubmitting extends LoginFormState {
  const LoginSubmitting();
}

// Pogrešan login ili lozinka.
class LoginRejected extends LoginFormState {
  const LoginRejected();
}

// Prijava nije stigla do odgovora servera. Tekst bira aplikacija po vrsti greške.
class LoginFailed extends LoginFormState {
  const LoginFailed(this.failure);

  final RepositoryFailure failure;

  @override
  List<Object?> get props => [failure];
}
