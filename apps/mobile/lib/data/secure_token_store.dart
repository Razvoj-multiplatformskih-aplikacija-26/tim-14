import 'package:api_client/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Token prijave u bezbednom skladištu platforme: Keystore na Androidu, Keychain na iOS-u.
// Lozinka se nigde ne čuva, samo token koji je server potpisao.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'casovi_session';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
