import 'dart:async';
import 'dart:io';

import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';

Future<void> main() async {
  final config = ServerConfig.fromEnvironment(serverEnvironment());
  final database = await Database.open(config.databaseUrl);
  final server = RelicServer(() => IOAdapter.bind(InternetAddress(config.host), port: config.port));
  await server.mountAndStart(
    buildHandler(
      corsOrigins: config.corsOrigins,
      lessons: PostgresLessons(database),
      verifications: PostgresVerifications(database),
      findUser: findUserIn(database),
    ),
  );
  stdout.writeln('Server on http://${config.host}:${config.port}');
  await _stopSignal();
  // The server first, so requests still running can finish their queries. Then the connections.
  await server.close();
  await database.close();
  stdout.writeln('Server stopped');
}

/// Ctrl-C locally, SIGTERM from `docker compose stop`. In the container this process is PID 1, and Linux
/// gives PID 1 no default signal handlers, so without this the container ignores SIGTERM until Docker kills it.
Future<void> _stopSignal() async {
  final stop = Completer<void>();
  final subscriptions = [
    for (final signal in [ProcessSignal.sigint, if (!Platform.isWindows) ProcessSignal.sigterm])
      signal.watch().listen((_) => stop.isCompleted ? null : stop.complete()),
  ];
  await stop.future;
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
}
