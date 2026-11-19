import 'package:server/server.dart';
import 'package:test/test.dart';

void main() {
  test('a hash is Argon2id in the standard encoded form', () async {
    final hash = await hashPassword('casovi-demo');

    expect(hash, startsWith(r'$argon2id$'));
    expect(hash, isNot(contains('casovi-demo')));
  });

  test('the right password verifies and a wrong one does not', () async {
    final hash = await hashPassword('casovi-demo');

    expect(await verifyPassword('casovi-demo', hash), isTrue);
    expect(await verifyPassword('casovi-demO', hash), isFalse);
  });

  test('the same password hashes differently each time, because of the salt', () async {
    final first = await hashPassword('casovi-demo');
    final second = await hashPassword('casovi-demo');

    expect(first, isNot(second));
    expect(await verifyPassword('casovi-demo', second), isTrue);
  });
}
