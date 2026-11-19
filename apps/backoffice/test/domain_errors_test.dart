import 'package:backoffice/text/domain_errors.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an empty request message and a too long one get different texts', () {
    const empty = InvalidRequestMessage(0);
    const tooLong = InvalidRequestMessage(RequestMessage.maxLength + 1);

    expect(empty.message, 'Poruka ne sme biti prazna.');
    expect(tooLong.message, contains('${RequestMessage.maxLength}'));
  });

  // Kad se pravilo menja uživo, menja se samo konstanta. Ovi testovi pokazuju da tekst ide za njom.
  test('rule texts take their numbers from the domain constants', () {
    expect(const RejectionReasonTooShort(3).message, contains('${RejectionReason.minLength}'));
    expect(const CancellationTooLate().message, contains('${cancellationNotice.inHours}'));
    expect(const TooManyPendingRequests().message, contains('$maxPendingRequests'));
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
