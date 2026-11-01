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
}
