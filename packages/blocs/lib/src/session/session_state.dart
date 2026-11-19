import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

// Zašto je korisnik odjavljen. Ekran za prijavu po tome bira poruku.
enum SignOutReason { loggedOut, expired, unreachable, roleNotAllowed }

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

// Još se ne zna da li sesija postoji (pre nego što se vrati odgovor na proveru). Aplikacija tada pokazuje splash.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SignedOut extends SessionState {
  const SignedOut({this.reason});

  // null znači da se u ovom pokretanju niko nije ni prijavio, pa nema šta da se objasni.
  final SignOutReason? reason;

  @override
  List<Object?> get props => [reason];
}

class SignedIn extends SessionState {
  const SignedIn(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}
