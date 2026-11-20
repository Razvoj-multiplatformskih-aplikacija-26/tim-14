import 'package:blocs/blocs.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'dependencies.dart';
import 'router.dart';

// Adresa servera se menja bez izmene koda: flutter run --dart-define=SERVER_URL=http://…
const _serverUrl = String.fromEnvironment('SERVER_URL', defaultValue: 'http://localhost:8080');

// Demo bez servera, sa lažnim podacima iz KT1: flutter run --dart-define=FAKE_DATA=true
const _fakeData = bool.fromEnvironment('FAKE_DATA');

// Ovde se svi objekti prave jednom. Ekrani ih dobijaju preko providera u BackofficeApp.
void main() {
  final dependencies = _fakeData
      ? BackofficeDependencies.fake(DateTime.now())
      : BackofficeDependencies.server(Uri.parse(_serverUrl));
  // Odmah pita da li sesija od ranije još važi. Dok ne stigne odgovor, ruter pokazuje splash.
  final session = createSessionBloc(dependencies.sessions)..add(const SessionRestoreRequested());

  runApp(BackofficeApp(dependencies: dependencies, session: session, router: createRouter(session)));
}
