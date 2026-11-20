/// TEMPORARY. The caller of a request, until the JWT middleware of I4 replaces [signedIn], [currentUser] and
/// [findUserIn]. Then this file is deleted.
library;

import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Sql;
import 'package:relic/relic.dart' hide Result;

import 'database.dart';
import 'http.dart' show problemResponse, signInRequired;

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
