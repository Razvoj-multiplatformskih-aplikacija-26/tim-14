sealed class ProfessorPageEvent {}

// Otvoren je profil profesora.
class ProfessorPageRequested extends ProfessorPageEvent {}

// Korisnik je kliknuo "Pokušaj ponovo" posle greške.
class ProfessorPageRetried extends ProfessorPageEvent {}

// Osvežavanje bez spinera (povuci nadole): npr. da se vidi termin koji je u međuvremenu zauzet.
class ProfessorPageRefreshed extends ProfessorPageEvent {}
