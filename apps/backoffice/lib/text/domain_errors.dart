import 'package:domain/domain.dart';

// Srpski tekst za svaku grešku iz domena. Switch nema default granu, pa nova greška u domenu
// ne prolazi kompajler dok ne dobije tekst ovde. Brojevi pravila se čitaju iz greške (npr.
// InvalidRequestMessage(:final max)), pa poruka kaže granicu koju je server stvarno primenio.
//
// Greške koje dobije kasni klijent (lista na ekranu je zastarela) kažu šta se u međuvremenu desilo.
// Posle njih Bloc tiho osveži listu, pa tekst može da kaže i to.
extension DomainErrorText on DomainError {
  String get message => switch (this) {
    InvalidRequestMessage(length: 0) => 'Poruka ne sme biti prazna.',
    InvalidRequestMessage(:final max) => 'Poruka može imati najviše $max znakova.',
    NoteTooLong(:final max) => 'Beleška može imati najviše $max znakova.',
    ReviewTextTooLong(:final max) => 'Recenzija može imati najviše $max znakova.',
    InvalidRating() => 'Ocena mora biti od ${Rating.min} do ${Rating.max}.',
    InvalidPrice() => 'Cena mora biti veća od 0 dinara.',
    InvalidLinkedInUrl() => 'LinkedIn adresa mora biti u obliku https://linkedin.com/in/ime.',
    RejectionReasonTooShort(:final min) => 'Razlog mora imati najmanje $min znakova.',
    SlotInPast() => 'Termin je već prošao.',
    SlotNotOnHalfHour() => 'Termin mora da počne na pun sat ili pola sata.',
    SlotOverlaps() => 'Termin se preklapa sa postojećim terminom.',
    TooSoonToRequest(:final notice) => 'Termin mora da se zatraži najkasnije ${notice.inHours} sata unapred.',
    TooManyPendingRequests(:final max) => 'Učenik već ima $max zahteva na čekanju.',
    AlreadyRequested() => 'Za ovaj termin zahtev je već poslat.',
    SlotTaken() => 'Termin je u međuvremenu zauzet. Lista je osvežena.',
    LessonStarted() => 'Čas je već počeo.',
    LessonNotStarted() => 'Čas još nije počeo. Ishod se upisuje posle početka.',
    CancellationTooLate(:final notice) => 'Čas može da se otkaže najkasnije ${notice.inHours} sata pre početka.',
    InvalidTransition(from: Cancelled(), to: Confirmed() || Rejected()) => 'Učenik je u međuvremenu povukao zahtev.',
    InvalidTransition(from: Cancelled()) => 'Učenik je u međuvremenu otkazao čas.',
    // Dugmad zavise od statusa, pa ostali prelazi stižu samo kad je lista zastarela.
    InvalidTransition() => 'Čas je u međuvremenu promenjen. Lista je osvežena.',
    LessonNotHeld() => 'Recenzija može da se napiše tek posle održanog časa.',
    AlreadyReviewed() => 'Za ovaj čas recenzija je već napisana.',
    InvalidVerificationTransition() => 'Drugi administrator je već odlučio o ovom profilu.',
    NotAllowed() => 'Ova radnja nije dozvoljena.',
    NotFound() => 'Zapis više ne postoji.',
    LessonChanged() => 'Čas je u međuvremenu promenjen. Lista je osvežena.',
  };
}
