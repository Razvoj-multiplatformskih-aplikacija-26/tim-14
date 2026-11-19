sealed class LoginFormEvent {
  const LoginFormEvent();
}

// Korisnik je kliknuo "Prijavi se" ili pritisnuo Enter. Lozinka postoji samo u ovom događaju, ne i u stanju.
class LoginSubmitted extends LoginFormEvent {
  const LoginSubmitted({required this.login, required this.password});

  final String login;
  final String password;
}
