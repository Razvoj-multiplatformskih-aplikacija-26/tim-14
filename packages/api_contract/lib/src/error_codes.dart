/// The `code` values of `ProblemDto`s. Clients switch on these, never on the HTTP status.
abstract final class ErrorCodes {
  // Rules of the domain, one per DomainError.
  static const invalidRequestMessage = 'invalid-request-message';
  static const noteTooLong = 'note-too-long';
  static const reviewTextTooLong = 'review-text-too-long';
  static const rejectionReasonTooShort = 'rejection-reason-too-short';
  static const invalidRating = 'invalid-rating';
  static const invalidPrice = 'invalid-price';
  static const invalidLinkedInUrl = 'invalid-linkedin-url';
  static const slotInPast = 'slot-in-past';
  static const slotNotOnHalfHour = 'slot-not-on-half-hour';
  static const tooSoonToRequest = 'too-soon-to-request';
  static const cancellationTooLate = 'cancellation-too-late';
  static const tooManyPendingRequests = 'too-many-pending-requests';
  static const slotOverlaps = 'slot-overlaps';
  static const alreadyRequested = 'already-requested';
  static const slotTaken = 'slot-taken';
  static const lessonStarted = 'lesson-started';
  static const lessonNotStarted = 'lesson-not-started';
  static const invalidTransition = 'invalid-transition';
  static const invalidVerificationTransition = 'invalid-verification-transition';
  static const lessonNotHeld = 'lesson-not-held';
  static const alreadyReviewed = 'already-reviewed';
  static const lessonChanged = 'lesson-changed';
  static const notAllowed = 'not-allowed';
  static const notFound = 'not-found';

  // Problems of the transport, not of a rule.
  static const badRequest = 'bad-request';
  static const signInRequired = 'sign-in-required';
  static const sessionExpired = 'session-expired';
  static const invalidCredentials = 'invalid-credentials';
  static const payloadTooLarge = 'payload-too-large';
  static const unsupportedMediaType = 'unsupported-media-type';
  static const serverError = 'server-error';
  static const serviceUnavailable = 'service-unavailable';
}
