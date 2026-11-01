import 'package:domain/domain.dart';

// Srpski tekst za svaku grešku iz domena, upućen učeniku.
// Switch nema default granu, pa nova greška u domenu ne prolazi kompajler dok ne dobije tekst ovde.
// Brojevi se čitaju iz konstanti domena, pa se tekst sam promeni kad se promeni pravilo.
extension DomainErrorText on DomainError {
  String get message => switch (this) {
    InvalidRequestMessage(length: 0) => 'Napiši profesoru šta ti je potrebno.',
    InvalidRequestMessage(:final length) =>
      'Poruka može imati najviše ${RequestMessage.maxLength} znakova (sada ima $length).',
    TooManyPendingRequests() =>
      'Već imaš $maxPendingRequests zahteva na čekanju. Povuci neki pre nego što pošalješ novi.',
    TooSoonToRequest() => 'Termin mora biti bar ${requestNotice.inHours} sata unapred.',
    AlreadyRequested() => 'Već si poslao zahtev za ovaj termin.',
    SlotTaken() => 'Ovaj termin je u međuvremenu zauzet.',
    CancellationTooLate() => 'Čas može da se otkaže najkasnije ${cancellationNotice.inHours} sata pre početka.',
    LessonStarted() => 'Čas je već počeo.',
    InvalidTransition() || LessonChanged() => 'Ova promena časa nije moguća.',
    NotAllowed() => 'Nemaš dozvolu za ovu radnju.',
    NotFound() => 'Traženi podatak ne postoji.',
    // Ove greške učenik u KT1 ne može da dobije, pa imaju kratak opšti tekst.
    NoteTooLong() ||
    ReviewTextTooLong() ||
    InvalidRating() ||
    InvalidPrice() ||
    InvalidLinkedInUrl() ||
    RejectionReasonTooShort() ||
    SlotInPast() ||
    SlotNotOnHalfHour() ||
    SlotOverlaps() ||
    LessonNotStarted() ||
    LessonNotHeld() ||
    AlreadyReviewed() ||
    InvalidVerificationTransition() => 'Ova radnja trenutno nije moguća.',
  };
}
