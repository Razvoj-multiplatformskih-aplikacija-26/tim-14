import 'dart:async';

sealed class ProfessorsEvent {}

// Ekran "Profesori" je otvoren.
class ProfessorsRequested extends ProfessorsEvent {}

// Korisnik je kliknuo "Pokušaj ponovo" posle greške.
class ProfessorsRetried extends ProfessorsEvent {}

// Korisnik je stigao do kraja liste, ili je kliknuo "Pokušaj ponovo" kad sledeća strana nije stigla.
class ProfessorsNextPageRequested extends ProfessorsEvent {}

// Osvežavanje bez spinera (povuci nadole): ponovo od prve strane, a lista ostaje na ekranu dok ona ne stigne.
class ProfessorsRefreshed extends ProfessorsEvent {
  ProfessorsRefreshed({this.done});

  // Završi se kad osvežavanje stigne do kraja, uspešno ili ne. RefreshIndicator do tada drži svoj spiner.
  final Completer<void>? done;
}
