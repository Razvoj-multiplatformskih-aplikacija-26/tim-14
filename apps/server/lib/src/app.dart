import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';
import 'package:use_cases/use_cases.dart';

import 'cors.dart';
import 'http.dart';
import 'sessions.dart';
import 'staff_handlers.dart';

/// The whole HTTP surface of the server: routes plus the middleware every request passes through.
///
/// A request goes outside-in: logging, then CORS, then error handling, then the router. Routes under
/// `/sessions/current`, `/lessons` and `/verifications` also pass [SessionHandlers.signedIn] first.
///
/// The repositories come in from outside, the way Spring injects beans: `bin/server.dart` passes the Postgres
/// ones, a test may pass others.
Handler buildHandler({
  required List<String> corsOrigins,
  required LessonRepository lessons,
  required VerificationRepository verifications,
  required SessionHandlers sessions,
  Clock clock = const SystemClock(),
}) {
  final staff = StaffHandlers(lessons, verifications, clock);
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    // Sessions (I4)
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, sessions.current)
    ..delete(ApiPaths.currentSession, sessions.logOut)
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
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
