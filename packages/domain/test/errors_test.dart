import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  // Granica je deo greške: ista dužina sa drugom granicom je druga greška. Tako mapiranje sa servera
  // ne može da izgubi granicu, a da test to ne primeti.
  test('errors with the same value but a different limit are not equal', () {
    expect(const InvalidRequestMessage(301, max: 300), const InvalidRequestMessage(301, max: 300));
    expect(const InvalidRequestMessage(301, max: 300), isNot(const InvalidRequestMessage(301, max: 200)));
    expect(const NoteTooLong(501, max: 500), isNot(const NoteTooLong(501, max: 400)));
    expect(const ReviewTextTooLong(1001, max: 1000), isNot(const ReviewTextTooLong(1001, max: 900)));
    expect(const RejectionReasonTooShort(3, min: 10), isNot(const RejectionReasonTooShort(3, min: 15)));
    expect(const TooManyPendingRequests(max: 3), isNot(const TooManyPendingRequests(max: 2)));
    expect(
      const TooSoonToRequest(notice: Duration(hours: 24)),
      isNot(const TooSoonToRequest(notice: Duration(hours: 12))),
    );
    expect(
      const CancellationTooLate(notice: Duration(hours: 24)),
      isNot(const CancellationTooLate(notice: Duration(hours: 12))),
    );
  });

  test('equal errors have equal hash codes', () {
    expect(const TooManyPendingRequests(max: 3).hashCode, const TooManyPendingRequests(max: 3).hashCode);
    expect(
      const CancellationTooLate(notice: Duration(hours: 24)).hashCode,
      const CancellationTooLate(notice: Duration(hours: 24)).hashCode,
    );
  });

  test('every value object puts its own limit on its error', () {
    expect(
      RequestMessage.parse('a' * 301).errorOrNull,
      const InvalidRequestMessage(301, max: RequestMessage.maxLength),
    );
    expect(LessonNote.parse('a' * 501).errorOrNull, const NoteTooLong(501, max: LessonNote.maxLength));
    expect(ReviewText.parse('a' * 1001).errorOrNull, const ReviewTextTooLong(1001, max: ReviewText.maxLength));
    expect(
      RejectionReason.parse('kratko').errorOrNull,
      const RejectionReasonTooShort(6, min: RejectionReason.minLength),
    );
  });
}
