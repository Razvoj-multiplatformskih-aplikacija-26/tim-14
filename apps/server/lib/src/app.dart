import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';
import 'package:use_cases/use_cases.dart';

import 'cors.dart';
import 'http.dart';
import 'staff_handlers.dart';
import 'stand_ins.dart';

/// The whole HTTP surface of the server: routes plus the middleware every request passes through.
///
/// A request goes outside-in: logging, then CORS, then error handling, then the router. Routes under
/// `/lessons` and `/verifications` also pass [signedIn] first.
///
/// The repositories come in from outside, the way Spring injects beans: `bin/server.dart` passes the Postgres
/// ones, a test may pass others.
Handler buildHandler({
  required List<String> corsOrigins,
  required LessonRepository lessons,
  required VerificationRepository verifications,
  required FindUser findUser,
  Clock clock = const SystemClock(),
}) {
  final staff = StaffHandlers(lessons, verifications, clock);
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    // Staff (D6)
    ..post(ApiPaths.confirmation(':id'), staff.confirm)
    ..post(ApiPaths.rejection(':id'), staff.reject)
    ..post(ApiPaths.held(':id'), staff.held)
    ..post(ApiPaths.noShow(':id'), staff.noShow)
    ..get(ApiPaths.verifications, staff.verificationQueue)
    ..post(ApiPaths.approval(':id'), staff.approve)
    ..post(ApiPaths.verificationRejection(':id'), staff.rejectProfessor)
    // Every route under these two prefixes needs a caller, Ilija's student routes included.
    ..use(ApiPaths.lessons, signedIn(findUser))
    ..use(ApiPaths.verifications, signedIn(findUser))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
