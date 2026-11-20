import 'package:api_client/api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Token na desktopu čuva sistemski sef (macOS Keychain, Windows Credential Manager), ne običan fajl.
// Ovo je adapter za port TokenStore iz api_client: ApiClient zna samo za port, ne i za Keychain.
// Na webu se ne koristi: tamo sesiju nosi HttpOnly kolačić koji skripta ne može da pročita.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const _key = 'session-token';

  // Stari Keychain na macOS-u radi i bez profila za potpisivanje aplikacije, pa radi i u debug buildu.
  static const _storage = FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false));

  // Ako sef ne može da se pročita, ponašamo se kao da tokena nema: korisnik se samo ponovo prijavi.
  // Bez ovoga bi provera sesije pukla i aplikacija bi ostala na splash ekranu.
  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
