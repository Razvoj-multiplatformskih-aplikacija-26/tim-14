import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show QueryMode, ServerException, Sql;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/test_database.dart';

/// One professor with one slot, and two students who each asked for it.
const fixture = '''
INSERT INTO users (id, name, role) VALUES
  ('p1', 'Milica Petrović', 'professor'), ('s1', 'Ana Jovanović', 'student'), ('s2', 'Nikola Ilić', 'student');
INSERT INTO listings (id, professor_id, subject, level, city, description, price_rsd, duration_minutes)
  VALUES ('l1', 'p1', 'math', 'high_school', 'Beograd', 'Analiza', 2000, 60);
INSERT INTO slots (id, listing_id, professor_id, starts_at, duration_minutes)
  VALUES ('sl1', 'l1', 'p1', now() + interval '3 days', 60);
INSERT INTO lessons (id, slot_id, listing_id, professor_id, professor_name, student_id, student_name,
                     starts_at, duration_minutes, message, created_at, status)
  SELECT id, 'sl1', 'l1', 'p1', 'Milica Petrović', student, name, now() + interval '3 days', 60, 'Zdravo', now(), 'pending'
  FROM (VALUES ('lesson-ana', 's1', 'Ana Jovanović'), ('lesson-nikola', 's2', 'Nikola Ilić')) AS requests (id, student, name);
''';

void main() {
  test('an unreachable database is a RepositoryException', () async {
    await expectLater(
      Database.open('postgres://casovi:casovi@127.0.0.1:1/casovi?sslmode=disable'),
      throwsA(isA<RepositoryException>()),
    );
  });

  group('on $testDatabaseName', tags: 'db', () {
    late Database database;

    setUpAll(() async => database = await createTestDatabase());
    setUp(() => truncateTables(database));
    tearDownAll(() => database.close());

    Future<int> count(String sql) => database.run((db) async => (await db.execute(sql)).single.single! as int);

    Future<Result<String>> confirm(String lesson) => database.transaction((tx) async {
      await tx.execute(
        Sql.named("UPDATE lessons SET status = 'confirmed', status_at = now() WHERE id = @id AND status = 'pending'"),
        parameters: {'id': lesson},
      );
      return Success(lesson);
    });

    test('the pool connects and SELECT 1 works', () async {
      expect(await count('SELECT 1'), 1);
    });

    test('a second confirmed lesson for one slot is SlotTaken', () async {
      await database.run((db) => db.execute(fixture, queryMode: QueryMode.simple));

      expect(await confirm('lesson-ana'), const Success('lesson-ana'));
      expect(await confirm('lesson-nikola'), const Failure<String>(SlotTaken()));
      expect(await count("SELECT count(*) FROM lessons WHERE status = 'confirmed'"), 1);
    });

    test('a Success commits, a Failure rolls back', () async {
      Future<Result<void>> insertUser(String id, Result<void> outcome) => database.transaction((tx) async {
        await tx.execute(
          Sql.named("INSERT INTO users (id, name, role) VALUES (@id, 'Test', 'student')"),
          parameters: {'id': id},
        );
        return outcome;
      });

      await insertUser('u-kept', const Success(null));
      await insertUser('u-undone', const Failure(LessonChanged()));

      expect(await count("SELECT count(*) FROM users WHERE id = 'u-kept'"), 1);
      expect(await count("SELECT count(*) FROM users WHERE id = 'u-undone'"), 0);
    });

    test('a mistake in our SQL is not a RepositoryException, so it stays a 500', () async {
      await expectLater(
        database.run((db) => db.execute('SELECT * FROM no_such_table')),
        throwsA(isA<ServerException>()),
      );
    });

    test('the pool uses more than one connection at a time', () async {
      Future<int> backend() => count('SELECT pg_backend_pid() FROM pg_sleep(0.2)');

      final pids = await Future.wait([backend(), backend()]);

      expect(pids.toSet(), hasLength(2));
    });
  });
}
