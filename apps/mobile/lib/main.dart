import 'package:flutter/material.dart';

import 'app.dart';
import 'data/secure_token_store.dart';
import 'dependencies.dart';
import 'server_address.dart';

// Bez servera, nad demo podacima: flutter run --dart-define=FAKE_DATA=true
const _fakeData = bool.fromEnvironment('FAKE_DATA');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = _fakeData
      ? AppDependencies.fake()
      : AppDependencies.server(baseUri: serverAddress(), tokens: const SecureTokenStore());
  runApp(App(dependencies: dependencies));
}
