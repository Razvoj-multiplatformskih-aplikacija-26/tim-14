sealed class ProfessorPageEvent {}

// Otvoren je profil profesora.
class ProfessorPageRequested extends ProfessorPageEvent {}

// Korisnik je kliknuo "Pokušaj ponovo" posle greške.
class ProfessorPageRetried extends ProfessorPageEvent {}
