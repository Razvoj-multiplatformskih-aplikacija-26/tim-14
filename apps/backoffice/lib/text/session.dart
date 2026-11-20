import 'package:blocs/blocs.dart';

const wrongCredentialsText = 'Pogrešno korisničko ime ili lozinka.';

// Zašto je korisnik na ekranu za prijavu. Bloc javlja samo razlog, a tekst pravi aplikacija,
// jer mobilna za istog učenika kaže nešto drugo.
extension SignOutReasonText on SignOutReason {
  // null: nema šta da se objasni, korisnik se sam odjavio.
  String? get notice => switch (this) {
    SignOutReason.loggedOut => null,
    SignOutReason.expired => 'Prijava je istekla. Prijavi se ponovo.',
    SignOutReason.unreachable => 'Nema veze sa serverom.',
    SignOutReason.roleNotAllowed => 'Backoffice je za profesore i administratore. Učenici koriste mobilnu aplikaciju.',
  };
}
