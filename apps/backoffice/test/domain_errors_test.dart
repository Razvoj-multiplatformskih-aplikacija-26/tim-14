import 'package:backoffice/text/domain_errors.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an empty request message and a too long one get different texts', () {
    const empty = InvalidRequestMessage(0, max: 300);
    const tooLong = InvalidRequestMessage(301, max: 300);

    expect(empty.message, 'Poruka ne sme biti prazna.');
    expect(tooLong.message, 'Poruka može imati najviše 300 znakova.');
  });

  // Granice ovde namerno nisu jednake konstantama u domenu: tako izgleda greška sa servera na kome je
  // pravilo promenjeno posle izgradnje aplikacije. Tekst mora da pokaže broj iz greške.
  test('rule texts take their numbers from the error, not from the domain constants', () {
    expect(const InvalidRequestMessage(250, max: 200).message, 'Poruka može imati najviše 200 znakova.');
    expect(const NoteTooLong(450, max: 400).message, 'Beleška može imati najviše 400 znakova.');
    expect(const ReviewTextTooLong(900, max: 800).message, 'Recenzija može imati najviše 800 znakova.');
    expect(const RejectionReasonTooShort(3, min: 15).message, 'Razlog mora imati najmanje 15 znakova.');
    expect(
      const CancellationTooLate(notice: Duration(hours: 12)).message,
      'Čas može da se otkaže najkasnije 12 sata pre početka.',
    );
    expect(
      const TooSoonToRequest(notice: Duration(hours: 48)).message,
      'Termin mora da se zatraži najkasnije 48 sata unapred.',
    );
    expect(const TooManyPendingRequests(max: 2).message, 'Učenik već ima 2 zahteva na čekanju.');
  });

  // Kasni klijent: lista na ekranu je zastarela, pa tekst kaže šta se u međuvremenu desilo.
  test('a late client is told what changed meanwhile', () {
    final at = DateTime.utc(2026, 11, 20, 10);
    final cancelled = Cancelled(by: const UserId('ana'), at: at);

    expect(const SlotTaken().message, 'Termin je u međuvremenu zauzet. Lista je osvežena.');
    expect(
      InvalidTransition(
        from: cancelled,
        to: Confirmed(at: at),
      ).message,
      'Učenik je u međuvremenu povukao zahtev.',
    );
    expect(
      InvalidTransition(
        from: cancelled,
        to: Rejected(cause: RejectionCause.byProfessor, at: at),
      ).message,
      'Učenik je u međuvremenu povukao zahtev.',
    );
    expect(
      InvalidTransition(
        from: cancelled,
        to: Held(at: at),
      ).message,
      'Učenik je u međuvremenu otkazao čas.',
    );
    expect(
      InvalidTransition(
        from: Confirmed(at: at),
        to: Confirmed(at: at),
      ).message,
      'Čas je u međuvremenu promenjen. Lista je osvežena.',
    );
    expect(const LessonChanged().message, 'Čas je u međuvremenu promenjen. Lista je osvežena.');
    expect(
      InvalidVerificationTransition(
        from: Verified(by: const UserId('drugi-admin'), at: at),
        to: Verified(by: const UserId('admin'), at: at),
      ).message,
      'Drugi administrator je već odlučio o ovom profilu.',
    );
  });
}
