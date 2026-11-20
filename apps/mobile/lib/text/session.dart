import 'package:blocs/blocs.dart';
import 'package:use_cases/use_cases.dart';

import 'failures.dart';

// Zašto je učenik na ekranu za prijavu. Prikazuje se iznad polja, u tonu upozorenja.
extension SignOutReasonText on SignOutReason {
  String? get message => switch (this) {
    SignOutReason.loggedOut => null,
    SignOutReason.expired => 'Prijava je istekla. Prijavi se ponovo.',
    SignOutReason.unreachable => 'Nema veze sa serverom.',
    SignOutReason.roleNotAllowed => 'Mobilna aplikacija je za učenike. Profesori i administratori rade u backoffice-u.',
  };
}

// Zašto poslednji pokušaj prijave nije uspeo, ili null dok greške nema.
String? loginErrorText(LoginFormState state) => switch (state) {
  LoginIdle() || LoginSubmitting() => null,
  LoginRejected() => 'Pogrešno korisničko ime ili lozinka.',
  LoginFailed(failure: RepositoryFailure.unreachable) => 'Nema veze sa serverom.',
  LoginFailed(:final failure) => failure.message,
};
