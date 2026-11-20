import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';
import 'package:use_cases/use_cases.dart';

import 'cors.dart';
import 'http.dart';
import 'public_handlers.dart';
import 'sessions.dart';
import 'staff_handlers.dart';
import 'student_handlers.dart';

/// The whole HTTP surface of the server: routes plus the middleware every request passes through.
///
/// A request goes outside-in: logging, then CORS, then error handling, then the router. Routes under
/// `/sessions/current`, `/lessons` and `/verifications` also pass [SessionHandlers.signedIn] first, and the public
/// `/professors` routes pass [SessionHandlers.optionallySignedIn].
///
/// The repositories come in from outside, the way Spring injects beans: `bin/server.dart` passes the Postgres
/// ones, a test may pass others.
Handler buildHandler({
  required List<String> corsOrigins,
  required LessonRepository lessons,
  required ProfessorRepository professors,
  required VerificationRepository verifications,
  required SessionHandlers sessions,
  Clock clock = const SystemClock(),
}) {
  final public = PublicHandlers(professors, lessons);
  final staff = StaffHandlers(lessons, verifications, clock);
  final student = StudentHandlers(lessons, professors, clock);
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    // Sessions (I4)
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, sessions.current)
    ..delete(ApiPaths.currentSession, sessions.logOut)
    // Public, without signing in (I5)
    ..get(ApiPaths.professors, public.professors)
    ..get(ApiPaths.professor(':id'), public.profile)
    ..get(ApiPaths.listingsOf(':id'), public.listings)
    ..get(ApiPaths.slotsOf(':id'), public.slots)
    ..get(ApiPaths.takenSlotsOf(':id'), public.takenSlots)
    // Lessons of the student; the two reads serve the professor too (I5)
    ..get(ApiPaths.lessons, student.lessons)
    ..get(ApiPaths.lesson(':id'), student.lesson)
    ..post(ApiPaths.lessons, student.request)
    ..post(ApiPaths.withdrawal(':id'), student.withdraw)
    ..post(ApiPaths.cancellation(':id'), student.cancel)
    // Staff (D6)
    ..post(ApiPaths.confirmation(':id'), staff.confirm)
    ..post(ApiPaths.rejection(':id'), staff.reject)
    ..post(ApiPaths.held(':id'), staff.held)
    ..post(ApiPaths.noShow(':id'), staff.noShow)
    ..get(ApiPaths.verifications, staff.verificationQueue)
    ..post(ApiPaths.approval(':id'), staff.approve)
    ..post(ApiPaths.verificationRejection(':id'), staff.rejectProfessor)
    // Every route under these prefixes needs a caller, the student routes included. Logging in does not.
    ..use(ApiPaths.currentSession, sessions.signedIn)
    ..use(ApiPaths.lessons, sessions.signedIn)
    ..use(ApiPaths.verifications, sessions.signedIn)
    // The professor pages are public, but an admin who is signed in sees more there than a visitor.
    ..use(ApiPaths.professors, sessions.optionallySignedIn)
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
