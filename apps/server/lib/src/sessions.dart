import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

import 'account_store.dart';
import 'http.dart';
import 'passwords.dart';

/// Who is calling and until when, read from a token the server signed itself.
final class Session {
  const Session({required this.user, required this.expiresAt});

  final User user;
  final DateTime expiresAt;
}

/// The session of the current request. Scoped to one [Request], so two requests running at once never see each
/// other's caller. In Spring terms: what `SecurityContextHolder` holds, but per request instead of per thread.
final _session = ContextProperty<Session>('session');

/// Who is calling. Only behind [SessionHandlers.signedIn]; anywhere else it throws, which `handleErrors` answers
/// with 500, because a route that forgot the middleware is a bug in the server.
User currentUser(Request request) => _session.get(request).user;

/// Who is calling on a public route, or null for a visitor without a session.
User? optionalUser(Request request) => _session[request]?.user;

const signInRequired = ProblemDto(status: 401, code: ErrorCodes.signInRequired, title: 'Sign in first');
const sessionExpired = ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: 'Session expired or invalid');
const invalidCredentials = ProblemDto(
  status: 401,
  code: ErrorCodes.invalidCredentials,
  title: 'Wrong login or password',
);

const _algorithm = JWTAlgorithm.HS256;

/// Login, logout and the middleware that reads the caller from the token.
///
/// The token is a JWT signed with `JWT_SECRET`: `sub` is the user id, plus `name`, `role` and `exp`. The server
/// checks the signature and the expiry on every call, without the database. Nobody else can make a valid token,
/// because nobody else has the secret, so the server knows who calls only from a token it issued itself, never
/// from an id the client sends. Rejected alternative: a sessions table, which could end a session before it
/// expires, but costs a query on every call.
final class SessionHandlers {
  SessionHandlers({required this.accounts, required String secret, required this.ttl, this.secureCookie = false})
    : _key = SecretKey(secret),
      _noAccountHash = hashPassword('no such account');

  final AccountStore accounts;

  /// How long a session lasts: `SESSION_TTL_MINUTES`.
  final Duration ttl;

  /// `COOKIE_SECURE`: true behind HTTPS, false for `http://localhost` in development.
  final bool secureCookie;

  final SecretKey _key;

  /// A hash checked when the login does not exist, so that answer takes as long as a wrong password and the
  /// timing does not tell which logins exist.
  final Future<String> _noAccountHash;

  /// The request goes on only with a valid session; otherwise 401 and the handler never runs.
  /// No token is `sign-in-required`; a token that is expired, or that the server did not sign, `session-expired`.
  Middleware get signedIn =>
      (Handler next) => (Request request) async {
        final token = _tokenOf(request);
        if (token == null) {
          return _unauthorized(signInRequired);
        }
        final session = _verify(token);
        if (session == null) {
          return _unauthorized(sessionExpired);
        }
        _session[request] = session;
        return next(request);
      };

  /// For public routes: a visitor goes on without a session, a signed-in caller goes on with one, so the handler
  /// can show an admin more than a visitor. A bad token is ignored, as if there were none.
  Middleware get optionallySignedIn =>
      (Handler next) => (Request request) async {
        if (_tokenOf(request) case final token?) {
          if (_verify(token) case final session?) {
            _session[request] = session;
          }
        }
        return next(request);
      };

  /// A token for [user], valid for [ttl] from now. The login issues one; tests issue them without passwords.
  String issue(User user) => JWT({
    'name': user.name,
    'role': user.role.name,
  }, subject: user.id.value).sign(_key, algorithm: _algorithm, expiresIn: ttl);

  /// `POST /sessions` with `{login, password, cookie}` → 201 and the session.
  ///
  /// With `cookie: true` (the browser) the token goes into an HttpOnly cookie that scripts cannot read, and is left
  /// out of the body. Otherwise (the phone and the desktop) it is in the body, for the app's secure storage.
  Future<Response> logIn(Request request) async {
    final body = LoginDto.fromJson(await readObject(request));
    final account = await accounts.account(body.login);
    final matches = await verifyPassword(body.password, account?.passwordHash ?? await _noAccountHash);
    if (account == null || !matches) {
      return _unauthorized(invalidCredentials);
    }

    final token = issue(account.user);
    final session = _verify(token)!;
    final dto = SessionDto(user: account.user.toDto(), expiresAt: session.expiresAt, token: body.cookie ? null : token);
    final response = json(201, dto.toJson());
    if (!body.cookie) {
      return response;
    }
    return response.copyWith(
      headers: response.headers.transform((headers) => headers.setCookie = _cookie(token, maxAge: ttl.inSeconds)),
    );
  }

  /// `GET /sessions/current` → who is signed in. The app asks this on start, to restore the session.
  Future<Response> current(Request request) async {
    final session = _session.get(request);
    return json(200, SessionDto(user: session.user.toDto(), expiresAt: session.expiresAt).toJson());
  }

  /// `DELETE /sessions/current` → 204, and the browser's cookie is cleared. A token in an app's storage cannot be
  /// taken back by the server: the app deletes it, and it stops working at its expiry anyway.
  Future<Response> logOut(Request request) async =>
      Response.noContent(headers: Headers.build((headers) => headers.setCookie = _cookie('', maxAge: 0)));

  SetCookieHeader _cookie(String value, {required int maxAge}) => SetCookieHeader(
    name: ApiCookies.session,
    value: value,
    path: Uri.parse('/'),
    maxAge: maxAge,
    httpOnly: true,
    secure: secureCookie,
    sameSite: SameSite.lax,
  );

  Response _unauthorized(ProblemDto problem) {
    final response = problemResponse(problem);
    return response.copyWith(
      headers: response.headers.transform((headers) => headers['WWW-Authenticate'] = ['Bearer']),
    );
  }

  /// The session in [token], or null if the signature, the algorithm, the expiry or the claims are not right.
  Session? _verify(String token) {
    try {
      // Only our algorithm: a token that says "none" or another algorithm is not ours, whatever it carries.
      if (JWT.decode(token).header?['alg'] != _algorithm.name) {
        return null;
      }
      return switch (JWT.verify(token, _key).payload) {
        {'sub': final String id, 'name': final String name, 'role': final String role, 'exp': final int exp} => Session(
          user: User(id: UserId(id), name: name, role: Role.values.byName(role)),
          expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
        ),
        _ => null,
      };
    } on JWTException {
      return null;
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// The phone and the desktop send `Authorization: Bearer <token>`; the browser sends the cookie by itself.
  String? _tokenOf(Request request) => switch (request.headers.authorization) {
    BearerAuthorizationHeader(:final token) => token,
    _ => request.headers.cookie?.getCookie(ApiCookies.session)?.value,
  };
}
