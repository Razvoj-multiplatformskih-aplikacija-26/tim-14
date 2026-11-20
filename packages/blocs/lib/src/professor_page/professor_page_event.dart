import 'dart:async';

sealed class ProfessorPageEvent {}

// Otvoren je profil profesora.
class ProfessorPageRequested extends ProfessorPageEvent {}

// Korisnik je kliknuo "Pokušaj ponovo" posle greške.
class ProfessorPageRetried extends ProfessorPageEvent {}

// Osvežavanje bez spinera (povuci nadole): npr. da se vidi termin koji je u međuvremenu zauzet.
class ProfessorPageRefreshed extends ProfessorPageEvent {
  ProfessorPageRefreshed({this.done});

  // Završi se kad osvežavanje stigne do kraja, uspešno ili ne. RefreshIndicator do tada drži svoj spiner.
  final Completer<void>? done;
}
