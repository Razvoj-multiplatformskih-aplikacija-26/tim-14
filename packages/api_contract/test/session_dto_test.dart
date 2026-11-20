import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  test('a login asks for a token unless it says cookie', () {
    const login = LoginDto(login: 'ucenik1', password: 'casovi-demo');

    expect(login.toJson(), {'login': 'ucenik1', 'password': 'casovi-demo', 'cookie': false});
    expect(LoginDto.fromJson(const {'login': 'ucenik1', 'password': 'casovi-demo'}).cookie, isFalse);
    expect(LoginDto.fromJson(const {'login': 'ucenik1', 'password': 'x', 'cookie': true}).cookie, isTrue);
    expect(() => LoginDto.fromJson(const {'login': 'ucenik1'}), throwsFormatException);
  });

  test('a session with a token survives a round trip', () {
    final session = SessionDto(
      user: const UserDto(id: 'ana-markovic', name: 'Ana Marković', role: 'student'),
      expiresAt: DateTime.utc(2026, 11, 21, 18),
      token: 'eyJ.abc.def',
    );

    final json = session.toJson();
    expect(json['expiresAt'], '2026-11-21T18:00:00.000Z');
    expect(SessionDto.fromJson(json).toJson(), json);
  });

  test('a session kept in a cookie has no token on the wire', () {
    final session = SessionDto(
      user: const UserDto(id: 'milica', name: 'Milica Jovanović', role: 'professor'),
      expiresAt: DateTime.utc(2026, 11, 21, 18),
    );

    expect(session.toJson().containsKey('token'), isFalse);
    expect(SessionDto.fromJson(session.toJson()).token, isNull);
  });
}
