import 'package:domain/domain.dart';

sealed class SessionEvent {
  const SessionEvent();
}

// Aplikacija se pokrenula: proveri da li sesija od ranije još važi.
class SessionRestoreRequested extends SessionEvent {
  const SessionRestoreRequested();
}

// Prijava je uspela. Šalje ga LoginFormBloc.
class SessionStarted extends SessionEvent {
  const SessionStarted(this.user);

  final User user;
}

// Korisnik je kliknuo "Odjava".
class SessionLogOutRequested extends SessionEvent {
  const SessionLogOutRequested();
}

// Server je odbio istekao token. Bloc ga sam šalje kad repozitorijum javi isticanje.
class SessionExpired extends SessionEvent {
  const SessionExpired();
}
