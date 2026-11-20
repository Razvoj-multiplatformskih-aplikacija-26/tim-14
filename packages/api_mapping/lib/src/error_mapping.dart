import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'lesson_mapping.dart';
import 'professor_mapping.dart';

/// The server's half: a refusal of a domain rule as a problem response. The switch has no default, so a new
/// [DomainError] does not compile until it gets a code here. The rule's numbers go along (`value`, `min`, `max`,
/// `minutes`); the text for the user is made by the client.
extension DomainErrorMapping on DomainError {
  ProblemDto toProblem() => switch (this) {
    InvalidRequestMessage(:final length, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidRequestMessage,
      title: 'Request message empty or too long',
      value: length,
      max: max,
    ),
    NoteTooLong(:final length, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.noteTooLong,
      title: 'Lesson note too long',
      value: length,
      max: max,
    ),
    ReviewTextTooLong(:final length, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.reviewTextTooLong,
      title: 'Review text too long',
      value: length,
      max: max,
    ),
    RejectionReasonTooShort(:final length, :final min) => ProblemDto(
      status: 422,
      code: ErrorCodes.rejectionReasonTooShort,
      title: 'Rejection reason too short',
      value: length,
      min: min,
    ),
    InvalidRating(:final value) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidRating,
      title: 'Rating out of range',
      value: value,
    ),
    InvalidPrice(:final dinars) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidPrice,
      title: 'Price out of range',
      value: dinars,
    ),
    InvalidLinkedInUrl() => const ProblemDto(
      status: 422,
      code: ErrorCodes.invalidLinkedInUrl,
      title: 'Not a LinkedIn profile URL',
    ),
    SlotInPast() => const ProblemDto(status: 422, code: ErrorCodes.slotInPast, title: 'Slot is in the past'),
    SlotNotOnHalfHour() => const ProblemDto(
      status: 422,
      code: ErrorCodes.slotNotOnHalfHour,
      title: 'Slot does not start on a half hour',
    ),
    TooSoonToRequest(:final notice) => ProblemDto(
      status: 422,
      code: ErrorCodes.tooSoonToRequest,
      title: 'Slot starts too soon to request',
      minutes: notice.inMinutes,
    ),
    CancellationTooLate(:final notice) => ProblemDto(
      status: 422,
      code: ErrorCodes.cancellationTooLate,
      title: 'Too late to cancel',
      minutes: notice.inMinutes,
    ),
    TooManyPendingRequests(:final max) => ProblemDto(
      status: 409,
      code: ErrorCodes.tooManyPendingRequests,
      title: 'Too many pending requests',
      max: max,
    ),
    SlotOverlaps() => const ProblemDto(status: 409, code: ErrorCodes.slotOverlaps, title: 'Slot overlaps another slot'),
    AlreadyRequested() => const ProblemDto(
      status: 409,
      code: ErrorCodes.alreadyRequested,
      title: 'Slot already requested by this student',
    ),
    SlotTaken() => const ProblemDto(
      status: 409,
      code: ErrorCodes.slotTaken,
      title: 'Slot already has a confirmed lesson',
    ),
    LessonStarted() => const ProblemDto(status: 409, code: ErrorCodes.lessonStarted, title: 'Lesson already started'),
    LessonNotStarted() => const ProblemDto(
      status: 409,
      code: ErrorCodes.lessonNotStarted,
      title: 'Lesson has not started yet',
    ),
    InvalidTransition(:final from, :final to) => ProblemDto(
      status: 409,
      code: ErrorCodes.invalidTransition,
      title: 'Lesson cannot move to that status',
      from: from.toDto().toJson(),
      to: to.toDto().toJson(),
    ),
    InvalidVerificationTransition(:final from, :final to) => ProblemDto(
      status: 409,
      code: ErrorCodes.invalidVerificationTransition,
      title: 'Verification cannot move to that status',
      from: from.toDto().toJson(),
      to: to.toDto().toJson(),
    ),
    LessonNotHeld() => const ProblemDto(status: 409, code: ErrorCodes.lessonNotHeld, title: 'Lesson was not held'),
    AlreadyReviewed() => const ProblemDto(
      status: 409,
      code: ErrorCodes.alreadyReviewed,
      title: 'Lesson already reviewed',
    ),
    LessonChanged() => const ProblemDto(
      status: 409,
      code: ErrorCodes.lessonChanged,
      title: 'Lesson was changed by someone else',
    ),
    NotAllowed() => const ProblemDto(status: 403, code: ErrorCodes.notAllowed, title: 'Not allowed'),
    NotFound() => const ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found'),
  };
}

/// The client's half: the same [DomainError] back from a problem response, so the app shows the same text as
/// when it checks the rule itself.
///
/// Null when the problem is not a domain rule: a transport code (`sign-in-required`, `server-error`, …), a code
/// this app does not know yet because the server is newer, or a known code whose data is missing or holds a status
/// this app does not know. The app then shows a general message and keeps working, instead of failing.
extension ProblemMapping on ProblemDto {
  DomainError? toDomainError() {
    try {
      return _toDomainError();
    } on FormatException {
      return null;
    }
  }

  DomainError? _toDomainError() => switch (this) {
    ProblemDto(code: ErrorCodes.invalidRequestMessage, :final value?, :final max?) => InvalidRequestMessage(
      value,
      max: max,
    ),
    ProblemDto(code: ErrorCodes.noteTooLong, :final value?, :final max?) => NoteTooLong(value, max: max),
    ProblemDto(code: ErrorCodes.reviewTextTooLong, :final value?, :final max?) => ReviewTextTooLong(value, max: max),
    ProblemDto(code: ErrorCodes.rejectionReasonTooShort, :final value?, :final min?) => RejectionReasonTooShort(
      value,
      min: min,
    ),
    ProblemDto(code: ErrorCodes.invalidRating, :final value?) => InvalidRating(value),
    ProblemDto(code: ErrorCodes.invalidPrice, :final value?) => InvalidPrice(value),
    ProblemDto(code: ErrorCodes.invalidLinkedInUrl) => const InvalidLinkedInUrl(),
    ProblemDto(code: ErrorCodes.slotInPast) => const SlotInPast(),
    ProblemDto(code: ErrorCodes.slotNotOnHalfHour) => const SlotNotOnHalfHour(),
    ProblemDto(code: ErrorCodes.tooSoonToRequest, :final minutes?) => TooSoonToRequest(
      notice: Duration(minutes: minutes),
    ),
    ProblemDto(code: ErrorCodes.cancellationTooLate, :final minutes?) => CancellationTooLate(
      notice: Duration(minutes: minutes),
    ),
    ProblemDto(code: ErrorCodes.tooManyPendingRequests, :final max?) => TooManyPendingRequests(max: max),
    ProblemDto(code: ErrorCodes.slotOverlaps) => const SlotOverlaps(),
    ProblemDto(code: ErrorCodes.alreadyRequested) => const AlreadyRequested(),
    ProblemDto(code: ErrorCodes.slotTaken) => const SlotTaken(),
    ProblemDto(code: ErrorCodes.lessonStarted) => const LessonStarted(),
    ProblemDto(code: ErrorCodes.lessonNotStarted) => const LessonNotStarted(),
    ProblemDto(code: ErrorCodes.invalidTransition, :final from?, :final to?) => InvalidTransition(
      from: LessonStatusDto.fromJson(from).toDomain(),
      to: LessonStatusDto.fromJson(to).toDomain(),
    ),
    ProblemDto(code: ErrorCodes.invalidVerificationTransition, :final from?, :final to?) =>
      InvalidVerificationTransition(
        from: VerificationStatusDto.fromJson(from).toDomain(),
        to: VerificationStatusDto.fromJson(to).toDomain(),
      ),
    ProblemDto(code: ErrorCodes.lessonNotHeld) => const LessonNotHeld(),
    ProblemDto(code: ErrorCodes.alreadyReviewed) => const AlreadyReviewed(),
    ProblemDto(code: ErrorCodes.lessonChanged) => const LessonChanged(),
    ProblemDto(code: ErrorCodes.notAllowed) => const NotAllowed(),
    ProblemDto(code: ErrorCodes.notFound) => const NotFound(),
    _ => null,
  };
}
