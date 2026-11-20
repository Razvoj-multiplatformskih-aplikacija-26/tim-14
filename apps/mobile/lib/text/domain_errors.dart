import 'package:domain/domain.dart';

// Srpski tekst za svaku grešku iz domena, upućen učeniku.
// Switch nema default granu, pa nova greška u domenu ne prolazi kompajler dok ne dobije tekst ovde.
// Brojevi se čitaju iz greške, a ne iz konstanti domena. Ako server promeni granicu, a aplikacija je
// napravljena pre toga, poruka i dalje kaže granicu koju je server stvarno primenio.
extension DomainErrorText on DomainError {
  String get message => switch (this) {
    InvalidRequestMessage(length: 0) => 'Napiši profesoru šta ti je potrebno.',
    InvalidRequestMessage(:final length, :final max) => 'Poruka može imati najviše $max znakova (sada ima $length).',
    TooManyPendingRequests(:final max) => 'Već imaš $max zahteva na čekanju. Povuci neki pre nego što pošalješ novi.',
    TooSoonToRequest(:final notice) => 'Termin mora biti bar ${notice.inHours} sata unapred.',
    AlreadyRequested() => 'Zahtev za ovaj termin je već poslat.',
    SlotTaken() => 'Ovaj termin je u međuvremenu zauzet.',
    CancellationTooLate(:final notice) => 'Čas može da se otkaže najkasnije ${notice.inHours} sata pre početka.',
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
