import 'dart:io';

import 'package:postgres/postgres.dart' show QueryMode;
import 'package:server/server.dart';

/// A constant, never read from the environment, so a test can't drop the dev database by accident.
const testDatabaseName = 'casovi_test';

/// Creates [testDatabaseName] from scratch on the same Postgres as the dev database and migrates it.
///
/// Connects to the dev database (`DATABASE_URL`) only to drop and create the test one. Its data is untouched.
Future<Database> createTestDatabase() async {
  final devUrl = Uri.parse(
    serverEnvironment()['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL is not set. Copy .env.example to .env in the repository root.')),
  );
  final admin = await Database.open(devUrl.toString(), maxConnections: 1);
  try {
    await admin.run((db) async {
      await db.execute('DROP DATABASE IF EXISTS $testDatabaseName WITH (FORCE)');
      await db.execute('CREATE DATABASE $testDatabaseName');
    });
  } finally {
    await admin.close();
  }
  final database = await Database.open(devUrl.replace(path: '/$testDatabaseName').toString());
  await _migrate(database);
  return database;
}

/// Runs the `-- migrate:up` part of every migration, in file name order, the way dbmate does in Compose.
/// A simple-protocol query may hold many statements, and Postgres runs them as one transaction.
Future<void> _migrate(Database database) async {
  final migrations = [
    for (final entry in Directory('migrations').listSync())
      if (entry is File && entry.path.endsWith('.sql')) entry,
  ]..sort((a, b) => a.path.compareTo(b.path));
  for (final migration in migrations) {
    final up = migration.readAsStringSync().split('-- migrate:down').first;
    await database.run((db) => db.execute(up, queryMode: QueryMode.simple));
  }
}

/// Empties every table. Tests call it in `setUp`, before each test, so a failed test leaves its rows behind
/// for a look in psql.
Future<void> truncateTables(Database database) => database.run((db) async {
  final tables = await db.execute(
    "SELECT string_agg(quote_ident(tablename), ', ') FROM pg_tables WHERE schemaname = 'public'",
  );
  await db.execute('TRUNCATE ${tables.single.single} CASCADE');
});
