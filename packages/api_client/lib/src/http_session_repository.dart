import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

/// Signing in over HTTP. The password goes to the server once and is never stored; what stays on the device is
/// the token the server signed (phone, desktop) or the cookie the browser keeps by itself.
final class HttpSessionRepository implements SessionRepository {
  const HttpSessionRepository(this._api);

  final ApiClient _api;

  /// The user, or null for a wrong login or password.
  @override
  Future<User?> logIn({required String login, required String password}) async {
    final body = LoginDto(login: login, password: password, cookie: _api.keepsSessionInCookie);
    final answer = await _api.post(ApiPaths.sessions, body: body.toJson());
    if (answer case ApiRefused(problem: ProblemDto(code: ErrorCodes.invalidCredentials))) return null;
    final session = accepted(answer, (json) => SessionDto.fromJson(object(json)));
    if (session.token case final token?) await _api.tokens.write(token);
    return session.user.toDomain();
  }

  /// Who is still signed in when the app starts, or null. An app without a stored token does not even ask; an
  /// expired session is cleared from storage.
  @override
  Future<User?> current() async {
    if (!_api.keepsSessionInCookie && await _api.tokens.read() == null) return null;
    try {
      final answer = await _api.get(ApiPaths.currentSession);
      return accepted<User>(answer, (json) => SessionDto.fromJson(object(json)).user.toDomain());
    } on RepositoryException catch (error) {
      if (error.failure != RepositoryFailure.sessionExpired) rethrow;
      await _api.tokens.clear();
      return null;
    }
  }

  /// The token is cleared even when the server cannot be reached: logging out always works on the device.
  @override
  Future<void> logOut() async {
    try {
      await _api.delete(ApiPaths.currentSession);
    } finally {
      await _api.tokens.clear();
    }
  }

  @override
  Stream<void> get expirations => _api.expirations;
}
