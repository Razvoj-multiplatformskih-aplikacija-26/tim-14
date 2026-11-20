/// Every path of the HTTP API. The client calls `ApiPaths.withdrawal(lesson.id.value)`; the server registers the
/// route as `ApiPaths.withdrawal(':id')`, so both sides read the path from the same place.
abstract final class ApiPaths {
  static const health = '/health';

  static const sessions = '/sessions';
  static const currentSession = '/sessions/current';

  static const professors = '/professors';

  static String professor(String id) => '$professors/$id';

  static String listingsOf(String professorId) => '${professor(professorId)}/listings';

  static String slotsOf(String professorId) => '${professor(professorId)}/slots';

  static String takenSlotsOf(String professorId) => '${professor(professorId)}/taken-slots';

  static const lessons = '/lessons';

  static String lesson(String id) => '$lessons/$id';

  static String withdrawal(String id) => '${lesson(id)}/withdrawal';

  static String cancellation(String id) => '${lesson(id)}/cancellation';

  static String confirmation(String id) => '${lesson(id)}/confirmation';

  static String rejection(String id) => '${lesson(id)}/rejection';

  static String held(String id) => '${lesson(id)}/held';

  static String noShow(String id) => '${lesson(id)}/no-show';

  static const verifications = '/verifications';

  static String verification(String professorId) => '$verifications/$professorId';

  static String approval(String professorId) => '${verification(professorId)}/approval';

  static String verificationRejection(String professorId) => '${verification(professorId)}/rejection';

  static String linkedIn(String professorId) => '${verification(professorId)}/linkedin';
}

/// Query parameters. `GET /lessons` takes exactly one of [student], [professor] and [slot].
abstract final class ApiQuery {
  static const offset = 'offset';
  static const limit = 'limit';
  static const student = 'student';
  static const professor = 'professor';
  static const slot = 'slot';
}

/// The browser keeps the session in this HttpOnly cookie; the phone and the desktop send a Bearer token instead.
abstract final class ApiCookies {
  static const session = 'casovi_session';
}
