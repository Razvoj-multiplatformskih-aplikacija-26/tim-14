import 'json.dart';

/// `POST /sessions`. With [cookie] the server answers with an HttpOnly cookie and no token (the browser);
/// without it, with a token in the body (the phone and the desktop).
final class LoginDto {
  const LoginDto({required this.login, required this.password, this.cookie = false});

  final String login;
  final String password;
  final bool cookie;

  Map<String, Object?> toJson() => {'login': login, 'password': password, 'cookie': cookie};

  factory LoginDto.fromJson(Map<String, Object?> json) => LoginDto(
    login: jsonString(json, 'login'),
    password: jsonString(json, 'password'),
    cookie: json['cookie'] == true,
  );
}

/// [role] is the name of the domain's `Role`: `student`, `professor` or `admin`.
final class UserDto {
  const UserDto({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'role': role};

  factory UserDto.fromJson(Map<String, Object?> json) =>
      UserDto(id: jsonString(json, 'id'), name: jsonString(json, 'name'), role: jsonString(json, 'role'));
}

/// The answer to `POST /sessions` and `GET /sessions/current`. [token] is absent when the cookie carries the session.
final class SessionDto {
  const SessionDto({required this.user, required this.expiresAt, this.token});

  final UserDto user;
  final DateTime expiresAt;
  final String? token;

  Map<String, Object?> toJson() => {'user': user.toJson(), 'expiresAt': instantToJson(expiresAt), 'token': ?token};

  factory SessionDto.fromJson(Map<String, Object?> json) => SessionDto(
    user: UserDto.fromJson(jsonObject(json['user'])),
    expiresAt: jsonInstant(json, 'expiresAt'),
    token: jsonOptionalString(json, 'token'),
  );
}
