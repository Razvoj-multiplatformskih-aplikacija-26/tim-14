sealed class RequestFormEvent {}

// Otvorena je forma, učitavaju se termin i oglas. Isti događaj šalje i "Pokušaj ponovo".
class RequestFormStarted extends RequestFormEvent {}

// Korisnik je promenio tekst poruke.
class MessageChanged extends RequestFormEvent {
  MessageChanged(this.text);

  final String text;
}

// Korisnik je kliknuo "Pošalji zahtev".
class RequestSubmitted extends RequestFormEvent {}
