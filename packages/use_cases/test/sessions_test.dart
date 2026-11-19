import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  late InMemorySessionRepository sessions;

  setUp(() => sessions = InMemorySessionRepository({'ucenik1': ('casovi-demo', student)}));

  test('LogIn trims spaces around the login, not around the password', () async {
    final user = await LogIn(sessions)(login: '  ucenik1 ', password: 'casovi-demo');

    expect(user, student);
    expect(sessions.lastLogin, 'ucenik1');
  });

  test('a wrong password gives no user', () async {
    final user = await LogIn(sessions)(login: 'ucenik1', password: ' casovi-demo');

    expect(user, isNull);
  });

  test('RestoreSession returns who is signed in, and LogOut ends it', () async {
    await LogIn(sessions)(login: 'ucenik1', password: 'casovi-demo');

    expect(await RestoreSession(sessions)(), student);

    await LogOut(sessions)();

    expect(await RestoreSession(sessions)(), isNull);
  });
}
