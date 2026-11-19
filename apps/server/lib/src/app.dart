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
    // Staff (D6). The paths move into ApiPaths when Ilija's I2 adds them.
    ..post('/lessons/:id/confirmation', staff.confirm)
    ..post('/lessons/:id/rejection', staff.reject)
    ..post('/lessons/:id/held', staff.held)
    ..post('/lessons/:id/no-show', staff.noShow)
    ..get('/verifications', staff.verificationQueue)
    ..post('/verifications/:id/approval', staff.approve)
    ..post('/verifications/:id/rejection', staff.rejectProfessor)
    // Every route under these two prefixes needs a caller, Ilija's student routes included.
    ..use('/lessons', signedIn(findUser))
    ..use('/verifications', signedIn(findUser))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
