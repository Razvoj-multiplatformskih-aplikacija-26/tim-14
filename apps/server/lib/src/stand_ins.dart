/// TEMPORARY. Everything here stands in for a piece of Ilija's I1–I4 that is not merged yet. The handlers call
/// these names; when his pieces land, this file is deleted and the handlers switch over:
///
/// | Here                                    | Replaced by                                     |
/// |-----------------------------------------|-------------------------------------------------|
/// | [signedIn], [currentUser], [findUserIn] | I4: the JWT middleware and its `currentUser`     |
/// | [canView]                               | I1: `AccessPolicy.canView`                       |
/// | [problemOf]                             | I3: `error.toProblem()`                          |
/// | [lessonJson], [profileJson], …          | I2/I3: `lesson.toDto().toJson()`, …              |
///
/// The JSON follows §1.4 of the KT2 plan, so the DTOs should produce the same shape.
library;

import 'package:api_contract/api_contract.dart' show ProblemDto;
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Sql;
import 'package:relic/relic.dart' hide Result;

import 'database.dart';
import 'http.dart' show problemResponse, signInRequired;
import 'rows.dart' show lessonStatusNameOf, rejectionCauseNameOf, verificationNameOf;

// ---------------------------------------------------------------------------------------------------------------
// The caller (until I4)

/// Looks a user up by id. Here: in `users`. After I4 the signed token carries the user and no lookup is needed.
typedef FindUser = Future<User?> Function(UserId id);

/// The caller of the current request. In Spring terms: what `SecurityContextHolder` holds, but scoped to one
/// [Request] instead of one thread, so two requests running at once never see each other's caller.
final _caller = ContextProperty<User>('caller');

/// Who is calling. Only valid behind [signedIn]; anywhere else it throws, which `handleErrors` answers with 500,
/// because a route that forgot [signedIn] is a bug in the server.
User currentUser(Request request) => _caller.get(request);

/// Lets a request through only with `Authorization: Bearer <user id>` of a user that exists. Otherwise
/// 401 `sign-in-required` and the handler never runs. In Spring terms: a `OncePerRequestFilter`.
///
/// The "token" is the bare user id, so anyone can be anyone. That is fine for curl on a laptop and never for
/// a real deployment. I4 replaces it with a JWT that only the server can sign. The header keeps its shape,
/// so curl commands only change their token value.
Middleware signedIn(FindUser findUser) =>
    (Handler next) => (Request request) async {
      final header = Headers.authorization[request.headers].valueOrNullIfInvalid;
      final user = header is BearerAuthorizationHeader ? await findUser(UserId(header.token)) : null;
      if (user == null) {
        return problemResponse(signInRequired);
      }
      _caller[request] = user;
      return next(request);
    };

FindUser findUserIn(Database database) =>
    (UserId id) => database.run((db) async {
      final rows = await db.execute(
        Sql.named('SELECT id, name, role FROM users WHERE id = @id'),
        parameters: {'id': id.value},
      );
      if (rows.isEmpty) {
        return null;
      }
      final column = rows.single.toColumnMap();
      return User(
        id: UserId(column['id'] as String),
        name: column['name'] as String,
        role: Role.values.byName(column['role'] as String),
      );
    });

// ---------------------------------------------------------------------------------------------------------------
// Who may see a lesson (until I1)

/// A lesson is visible to its own student and its own professor, and to nobody else.
bool canView(User user, Lesson lesson) =>
    (user.role == Role.student && user.id == lesson.studentId) ||
    (user.role == Role.professor && user.id == lesson.professorId);

// ---------------------------------------------------------------------------------------------------------------
// DomainError → ProblemDto (until I3)

/// The code, HTTP status and numbers for each domain error, as in §1.5. A switch over the sealed class with no
/// default: a new error does not compile until it gets a line here.
///
/// The limits (`max`, `min`, `minutes`) come from the domain's constants until I1 puts them on the errors.
ProblemDto problemOf(DomainError error) => switch (error) {
  final InvalidRequestMessage e => _problem(
    422,
    'invalid-request-message',
    'Request message empty or too long',
    value: e.length,
    max: RequestMessage.maxLength,
  ),
  final NoteTooLong e => _problem(
    422,
    'note-too-long',
    'Lesson note too long',
    value: e.length,
    max: LessonNote.maxLength,
  ),
  final ReviewTextTooLong e => _problem(
    422,
    'review-text-too-long',
    'Review text too long',
    value: e.length,
    max: ReviewText.maxLength,
  ),
  final RejectionReasonTooShort e => _problem(
    422,
    'rejection-reason-too-short',
    'Rejection reason too short',
    value: e.length,
    min: RejectionReason.minLength,
  ),
  final InvalidRating e => _problem(422, 'invalid-rating', 'Rating out of range', value: e.value),
  final InvalidPrice e => _problem(422, 'invalid-price', 'Price out of range', value: e.dinars),
  InvalidLinkedInUrl() => _problem(422, 'invalid-linkedin-url', 'Not a LinkedIn profile URL'),
  SlotInPast() => _problem(422, 'slot-in-past', 'Slot is in the past'),
  SlotNotOnHalfHour() => _problem(422, 'slot-not-on-half-hour', 'Slot does not start on a half hour'),
  TooSoonToRequest() => _problem(
    422,
    'too-soon-to-request',
    'Slot starts too soon to request',
    minutes: requestNotice.inMinutes,
  ),
  CancellationTooLate() => _problem(
    422,
    'cancellation-too-late',
    'Too late to cancel',
    minutes: cancellationNotice.inMinutes,
  ),
  TooManyPendingRequests() => _problem(
    409,
    'too-many-pending-requests',
    'Too many pending requests',
    max: maxPendingRequests,
  ),
  SlotOverlaps() => _problem(409, 'slot-overlaps', 'Slot overlaps another slot'),
  AlreadyRequested() => _problem(409, 'already-requested', 'Slot already requested by this student'),
  SlotTaken() => _problem(409, 'slot-taken', 'Slot already has a confirmed lesson'),
  LessonStarted() => _problem(409, 'lesson-started', 'Lesson already started'),
  LessonNotStarted() => _problem(409, 'lesson-not-started', 'Lesson has not started yet'),
  final InvalidTransition e => _problem(
    409,
    'invalid-transition',
    'Lesson cannot move to that status',
    from: lessonStatusJson(e.from),
    to: lessonStatusJson(e.to),
  ),
  final InvalidVerificationTransition e => _problem(
    409,
    'invalid-verification-transition',
    'Verification cannot move to that status',
    from: verificationJson(e.from),
    to: verificationJson(e.to),
  ),
  LessonNotHeld() => _problem(409, 'lesson-not-held', 'Lesson was not held'),
  AlreadyReviewed() => _problem(409, 'already-reviewed', 'Lesson already reviewed'),
  LessonChanged() => _problem(409, 'lesson-changed', 'Lesson was changed by someone else'),
  NotAllowed() => _problem(403, 'not-allowed', 'Not allowed'),
  NotFound() => _problem(404, 'not-found', 'Not found'),
};

ProblemDto _problem(
  int status,
  String code,
  String title, {
  int? value,
  int? min,
  int? max,
  int? minutes,
  Map<String, Object?>? from,
  Map<String, Object?>? to,
}) => ProblemDto(
  status: status,
  code: code,
  title: title,
  value: value,
  min: min,
  max: max,
  minutes: minutes,
  from: from,
  to: to,
);

// ---------------------------------------------------------------------------------------------------------------
// Domain → JSON (until I2/I3)

/// UTC ISO-8601, the same as `instantToJson` in `api_contract` (not exported from there).
String _instant(DateTime instant) => instant.toUtc().toIso8601String();

/// `LessonDto` from §1.4, without `professorName` and `studentName`: `Lesson` has no names until I1.
Map<String, Object?> lessonJson(Lesson lesson) => {
  'id': lesson.id.value,
  'slotId': lesson.slotId.value,
  'listingId': lesson.listingId.value,
  'professorId': lesson.professorId.value,
  'studentId': lesson.studentId.value,
  'start': _instant(lesson.start),
  'durationMinutes': lesson.duration.minutes,
  'message': lesson.message.text,
  'createdAt': _instant(lesson.createdAt),
  'status': lessonStatusJson(lesson.status),
};

/// `{"type": …}` plus that status's fields. The type names are the database's names, the same as §1.4.
Map<String, Object?> lessonStatusJson(LessonStatus status) {
  final type = lessonStatusNameOf(status);
  if (status is Confirmed) {
    return {'type': type, 'at': _instant(status.at)};
  } else if (status is Rejected) {
    return {'type': type, 'cause': rejectionCauseNameOf(status.cause), 'at': _instant(status.at)};
  } else if (status is Cancelled) {
    return {'type': type, 'by': status.by.value, 'at': _instant(status.at)};
  } else if (status is Held) {
    return {'type': type, 'at': _instant(status.at), 'note': ?status.note?.text};
  } else if (status is NoShow) {
    return {'type': type, 'at': _instant(status.at)};
  }
  return {'type': type};
}

/// `ConfirmationDto`: the confirmed lesson and the ones rejected with it.
Map<String, Object?> confirmationJson(Confirmation confirmation) => {
  'confirmed': lessonJson(confirmation.confirmed),
  'rejected': [for (final lesson in confirmation.rejected) lessonJson(lesson)],
};

/// `ProfessorProfileDto` with the full verification. Only admin endpoints use it. The public endpoints (I5) must
/// first pass the profile through Ilija's `visibleTo`, so diploma, LinkedIn and reason stay admin-only.
Map<String, Object?> profileJson(ProfessorProfile profile) => {
  'id': profile.id.value,
  'fullName': profile.fullName,
  'city': profile.city.name,
  'bio': profile.bio,
  'education': [
    for (final item in profile.education)
      {'institution': item.institution, 'title': item.title, 'fromYear': item.fromYear, 'toYear': ?item.toYear},
  ],
  'experience': [
    for (final item in profile.experience)
      {'employer': item.employer, 'title': item.title, 'fromYear': item.fromYear, 'toYear': ?item.toYear},
  ],
  'verification': verificationJson(profile.verification),
};

Map<String, Object?> verificationJson(VerificationStatus status) {
  final type = verificationNameOf(status);
  if (status is AwaitingReview) {
    return {
      'type': type,
      'submittedAt': _instant(status.submittedAt),
      'diplomaFile': status.diplomaFile,
      'linkedIn': status.linkedIn.value,
    };
  } else if (status is Verified) {
    return {'type': type, 'by': status.by.value, 'at': _instant(status.at)};
  } else if (status is VerificationRejected) {
    return {'type': type, 'by': status.by.value, 'at': _instant(status.at), 'reason': status.reason.text};
  }
  return {'type': type};
}
