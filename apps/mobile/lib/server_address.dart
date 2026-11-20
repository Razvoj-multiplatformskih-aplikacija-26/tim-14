import 'package:flutter/foundation.dart';

// Gde je server, bez izmene koda:
// - Android emulator vidi računar na 10.0.2.2,
// - iOS simulator i desktop na localhost,
// - pravi telefon dobija adresu računara: flutter run --dart-define=SERVER_URL=http://192.168.1.10:8080
Uri serverAddress() {
  const configured = String.fromEnvironment('SERVER_URL');
  if (configured.isNotEmpty) return Uri.parse(configured);
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
  return Uri.parse('http://$host:8080');
}
