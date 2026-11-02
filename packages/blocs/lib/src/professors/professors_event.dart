sealed class ProfessorsEvent {}

// Ekran "Profesori" je otvoren.
class ProfessorsRequested extends ProfessorsEvent {}

// Korisnik je kliknuo "Pokušaj ponovo" posle greške.
class ProfessorsRetried extends ProfessorsEvent {}
