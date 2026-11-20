import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// What the other side gets: the JSON text, decoded again.
Map<String, Object?> overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

DomainError? backFromTheServer(DomainError error) =>
    ProblemDto.fromJson(overTheWire(error.toProblem().toJson())).toDomainError();

void main() {
  final at = DateTime.utc(2026, 11, 20, 10);
  final reason = RejectionReason.parse('Diploma nije čitljiva.').valueOrNull!;
  final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jelena').valueOrNull!;

  // One example of every DomainError. Whoever adds an error to the domain adds it here too, which shows in review.
  // The limits differ from the domain's constants on purpose: the number must come from the error.
  final errors = <DomainError>[
    const InvalidRequestMessage(0, max: 300),
    const InvalidRequestMessage(250, max: 200),
    const NoteTooLong(501, max: 500),
    const ReviewTextTooLong(1001, max: 1000),
    const RejectionReasonTooShort(3, min: 15),
    const InvalidRating(6),
    const InvalidPrice(0),
    const InvalidLinkedInUrl(),
    const SlotInPast(),
    const SlotNotOnHalfHour(),
    const TooSoonToRequest(notice: Duration(hours: 24)),
    const CancellationTooLate(notice: Duration(hours: 12)),
    const TooManyPendingRequests(max: 2),
    const SlotOverlaps(),
    const AlreadyRequested(),
    const SlotTaken(),
    const LessonStarted(),
    const LessonNotStarted(),
    InvalidTransition(
      from: Cancelled(by: const UserId('ana'), at: at),
      to: Confirmed(at: at),
    ),
    InvalidTransition(
      from: Held(at: at, note: LessonNote.parse('Odlično.').valueOrNull),
      to: Rejected(cause: RejectionCause.slotTaken, at: at),
    ),
    InvalidTransition(
      from: const Pending(),
      to: NoShow(at: at),
    ),
    InvalidVerificationTransition(
      from: Verified(by: const UserId('drugi-admin'), at: at),
      to: VerificationRejected(by: const UserId('admin'), at: at, reason: reason),
    ),
    InvalidVerificationTransition(
      from: const NotVerified(),
      to: AwaitingReview(submittedAt: at, diplomaFile: 'diploma.pdf', linkedIn: linkedIn),
    ),
    const LessonNotHeld(),
    const AlreadyReviewed(),
    const LessonChanged(),
    const NotAllowed(),
    const NotFound(),
  ];

  test('every domain error comes back from the server as the same error, limits included', () {
    for (final error in errors) {
      expect(backFromTheServer(error), error, reason: '$error');
    }
  });

  test('every domain error has its own code', () {
    final codesByType = <Type, String>{for (final error in errors) error.runtimeType: error.toProblem().code};
    expect(codesByType.values.toSet(), hasLength(codesByType.length));
  });

  test('the HTTP status follows the table of the plan', () {
    expect(const InvalidRequestMessage(301, max: 300).toProblem().status, 422);
    expect(const CancellationTooLate(notice: Duration(hours: 24)).toProblem().status, 422);
    expect(const TooManyPendingRequests(max: 3).toProblem().status, 409);
    expect(const SlotTaken().toProblem().status, 409);
    expect(const LessonChanged().toProblem().status, 409);
    expect(const NotAllowed().toProblem().status, 403);
    expect(const NotFound().toProblem().status, 404);
  });

  test('the problem carries the numbers of the rule, not a text for the user', () {
    expect(const InvalidRequestMessage(301, max: 300).toProblem().toJson(), {
      'type': ProblemDto.typeOf(ErrorCodes.invalidRequestMessage),
      'title': 'Request message empty or too long',
      'status': 422,
      'code': 'invalid-request-message',
      'value': 301,
      'max': 300,
    });
    expect(const CancellationTooLate(notice: Duration(hours: 24)).toProblem().minutes, 1440);
    expect(
      InvalidTransition(
        from: const Pending(),
        to: Confirmed(at: at),
      ).toProblem().from,
      {'type': 'pending'},
    );
  });

  group('an older app does not fail on what it does not know', () {
    test('a code it does not know is no domain error', () {
      const problem = ProblemDto(status: 409, code: 'lesson-limit-per-day', title: 'Too many lessons today', max: 5);
      expect(problem.toDomainError(), isNull);
    });

    test('a transport problem is no domain error', () {
      for (final code in [ErrorCodes.sessionExpired, ErrorCodes.serverError, ErrorCodes.badRequest]) {
        expect(
          ProblemDto(status: 400, code: code, title: '').toDomainError(),
          isNull,
          reason: code,
        );
      }
    });

    test('a known code without its numbers is no domain error', () {
      const problem = ProblemDto(status: 422, code: ErrorCodes.invalidRequestMessage, title: '', value: 301);
      expect(problem.toDomainError(), isNull);
    });

    test('a transition to a status it does not know is no domain error', () {
      const problem = ProblemDto(
        status: 409,
        code: ErrorCodes.invalidTransition,
        title: '',
        from: {'type': 'pending'},
        to: {'type': 'expired', 'at': '2026-11-20T10:00:00.000Z'},
      );
      expect(problem.toDomainError(), isNull);
    });
  });
}
