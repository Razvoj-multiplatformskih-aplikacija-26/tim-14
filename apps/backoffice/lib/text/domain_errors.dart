import 'package:domain/domain.dart';

// Srpski tekst za svaku grešku iz domena. Switch nema default granu, pa nova greška u domenu
// ne prolazi kompajler dok ne dobije tekst ovde. Brojevi dolaze iz konstanti domena.
extension DomainErrorText on DomainError {
  String get message => switch (this) {
    InvalidRequestMessage(length: 0) => 'Poruka ne sme biti prazna.',
    InvalidRequestMessage() => 'Poruka može imati najviše ${RequestMessage.maxLength} znakova.',
    NoteTooLong() => 'Beleška može imati najviše ${LessonNote.maxLength} znakova.',
    ReviewTextTooLong() => 'Recenzija može imati najviše ${ReviewText.maxLength} znakova.',
    InvalidRating() => 'Ocena mora biti od ${Rating.min} do ${Rating.max}.',
    InvalidPrice() => 'Cena mora biti veća od 0 dinara.',
    InvalidLinkedInUrl() => 'LinkedIn adresa mora biti u obliku https://linkedin.com/in/ime.',
    RejectionReasonTooShort() => 'Razlog mora imati najmanje ${RejectionReason.minLength} znakova.',
    SlotInPast() => 'Termin je već prošao.',
    SlotNotOnHalfHour() => 'Termin mora da počne na pun sat ili pola sata.',
    SlotOverlaps() => 'Termin se preklapa sa postojećim terminom.',
    TooSoonToRequest() => 'Termin mora da se zatraži najkasnije ${requestNotice.inHours} sata unapred.',
    TooManyPendingRequests() => 'Učenik već ima $maxPendingRequests zahteva na čekanju.',
    AlreadyRequested() => 'Za ovaj termin zahtev je već poslat.',
    SlotTaken() => 'Termin je već zauzet.',
    LessonStarted() => 'Čas je već počeo.',
    LessonNotStarted() => 'Čas još nije počeo. Ishod se upisuje posle početka.',
    CancellationTooLate() => 'Čas može da se otkaže najkasnije ${cancellationNotice.inHours} sata pre početka.',
    InvalidTransition() => 'Ova promena časa nije moguća.',
    LessonNotHeld() => 'Recenzija može da se napiše tek posle održanog časa.',
    AlreadyReviewed() => 'Za ovaj čas recenzija je već napisana.',
    InvalidVerificationTransition() => 'Ova promena verifikacije nije moguća.',
    NotAllowed() => 'Ova radnja nije dozvoljena.',
    NotFound() => 'Zapis više ne postoji.',
    LessonChanged() => 'Čas je u međuvremenu promenjen.',
  };
}
