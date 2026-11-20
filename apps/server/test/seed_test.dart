@Tags(['db'])
library;

import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show ResultRow;
import 'package:server/server.dart';
import 'package:test/test.dart';

import 'support/test_database.dart';

/// The defense morning, at an odd minute, so the "whole hours" rounding is exercised.
final seededAt = DateTime.utc(2026, 11, 22, 8, 41);

const demoPassword = 'test-demo-password';

void main() {
  late Database database;
  late PostgresLessons lessons;
  late PostgresProfessors professors;
  late PostgresVerifications verifications;
  final data = demoData(seededAt);
  final ana = data.logins['ucenik1']!;
  final nikola = data.logins['ucenik2']!;
  final milica = data.logins['profesor1']!;

  setUpAll(() async {
    database = await createTestDatabase();
    lessons = PostgresLessons(database);
    professors = PostgresProfessors(database);
    verifications = PostgresVerifications(database);
  });
  setUp(() => truncateTables(database));
  tearDownAll(() => database.close());

  Future<SeedOutcome> seed({String? password = demoPassword}) =>
      seedIfEmpty(database, demoPassword: password, now: seededAt);

  Future<List<ResultRow>> query(String sql) => database.run((db) => db.execute(sql));

  Future<int> count(String table) async => (await query('SELECT count(*) FROM $table')).single.single! as int;

  test('an empty database is seeded, and a second run writes nothing', () async {
    expect(await seed(), SeedOutcome.seeded);
    expect(await count('users'), data.users.length);
    expect(await count('lessons'), data.lessons.length);

    expect(await seed(), SeedOutcome.notEmpty);
    expect(await count('users'), data.users.length);
    expect(await count('lessons'), data.lessons.length);
  });

  test('without DEMO_PASSWORD nothing is written', () async {
    expect(await seed(password: null), SeedOutcome.noDemoPassword);
    expect(await count('users'), 0);
  });

  test('the four demo accounts sign in with the demo password, and nobody else has a login', () async {
    await seed();

    final rows = await query('SELECT login, role, password_hash FROM users WHERE login IS NOT NULL ORDER BY login');
    expect(
      [for (final row in rows) (row[0], row[1])],
      [('admin1', 'admin'), ('profesor1', 'professor'), ('ucenik1', 'student'), ('ucenik2', 'student')],
    );
    for (final row in rows) {
      final hash = row[2]! as String;
      expect(hash, startsWith(r'$argon2id$'));
      expect(await verifyPassword(demoPassword, hash), isTrue, reason: '${row[0]}');
    }
    expect(await verifyPassword('wrong password', rows.first[2]! as String), isFalse);
    expect(await count('users WHERE password_hash IS NULL'), data.users.length - 4);
  });

  test('at least 10 lessons, with every lesson status and every verification state', () async {
    await seed();

    expect(await count('lessons'), greaterThanOrEqualTo(10));
    final statuses = {for (final row in await query('SELECT DISTINCT status FROM lessons')) row.single};
    expect(statuses, {'pending', 'confirmed', 'rejected', 'cancelled', 'held', 'no_show'});
    final causes = {for (final row in await query('SELECT DISTINCT rejection_cause FROM lessons')) row.single};
    expect(causes, containsAll(['by_professor', 'slot_taken']));
    final states = {for (final row in await query('SELECT DISTINCT verification FROM professor_profiles')) row.single};
    expect(states, {'not_verified', 'awaiting_review', 'verified', 'rejected'});
  });

  test('every row reads back through the repositories as the same domain objects', () async {
    await seed();

    final stored = <Lesson>[];
    for (final profile in data.profiles) {
      expect(await professors.profile(profile.id), profile);
      expect(
        await professors.listingsOf(profile.id),
        unorderedEquals(data.listings.where((l) => l.professorId == profile.id)),
      );
      expect(
        await professors.slotsOf(profile.id),
        unorderedEquals(data.slots.where((s) => s.professorId == profile.id)),
      );
      stored.addAll(await lessons.lessonsOfProfessor(profile.id));
    }
    expect(stored, unorderedEquals(data.lessons));
  });

  test('the verification queue is the three awaiting review, the longest-waiting first', () async {
    await seed();

    final queue = await verifications.queue();

    expect([for (final profile in queue) profile.fullName], ['Dragan Simić', 'Milan Đurić', 'Jelena Marković']);
  });

  test("at any hour of seeding, no professor's slots overlap, all are on a half hour, and lessons sit on them", () {
    for (var hour = 0; hour < 24; hour++) {
      final data = demoData(DateTime.utc(2026, 11, 22, hour, 41));
      for (final slot in data.slots) {
        expect(isOnHalfHour(slot.start), isTrue, reason: '${slot.id} at $hour h');
        final others = data.slots.where((other) => other.id != slot.id && other.professorId == slot.professorId);
        expect(others.where(slot.overlaps), isEmpty, reason: '${slot.id} at $hour h');
      }
      for (final lesson in data.lessons) {
        final slot = data.slots.singleWhere((slot) => slot.id == lesson.slotId);
        expect(
          (slot.start, slot.duration, slot.listingId, slot.professorId),
          (lesson.start, lesson.duration, lesson.listingId, lesson.professorId),
          reason: '${lesson.id} at $hour h',
        );
      }
    }
  });

  group('the demo scenarios hold at the time of the seed', () {
    setUp(() => seed());

    test('three requests wait for one slot, and confirming one rejects the other two', () async {
      final milicasLessons = await lessons.lessonsOfProfessor(milica.id);
      final pendingBySlot = <SlotId, List<Lesson>>{};
      for (final lesson in milicasLessons.where((lesson) => lesson.status is Pending)) {
        pendingBySlot.putIfAbsent(lesson.slotId, () => []).add(lesson);
      }
      final shared = pendingBySlot.values.firstWhere((waiting) => waiting.length >= 3);
      expect({for (final lesson in shared) lesson.studentId}, containsAll([ana.id, nikola.id]));

      final result = confirmLesson(
        shared.first,
        by: milica,
        competing: await lessons.lessonsForSlot(shared.first.slotId),
        now: seededAt,
      );

      expect(result, isA<Success<Confirmation>>());
      expect(result.valueOrNull!.rejected, hasLength(shared.length - 1));
    });

    test("Ana's third request goes through and her fourth is refused", () async {
      final mine = await lessons.lessonsOf(ana.id);
      final slots = await professors.slotsOf(milica.id);
      final free = freeSlots(
        slots,
        taken: await lessons.takenSlotsOf(milica.id),
        now: seededAt,
      ).where((slot) => !mine.any((lesson) => lesson.slotId == slot.id)).toList();
      final message = RequestMessage.parse('Može li još jedan čas?').valueOrNull!;

      Result<Lesson> request(Slot slot, List<Lesson> studentLessons) => requestLesson(
        id: LessonId('new-${slot.id.value}'),
        slot: slot,
        professorName: milica.name,
        by: ana,
        message: message,
        studentLessons: studentLessons,
        slotLessons: const [],
        now: seededAt,
      );

      final third = request(free[0], mine);
      expect(third, isA<Success<Lesson>>());
      final fourth = request(free[1], [...mine, third.valueOrNull!]);
      expect(fourth, const Failure<Lesson>(TooManyPendingRequests(max: maxPendingRequests)));
    });

    test('a confirmed lesson of Milica has started, so she can record it as held', () async {
      final started = (await lessons.lessonsOfProfessor(milica.id))
          .where((lesson) => lesson.status is Confirmed && hasStarted(lesson, now: seededAt));

      expect(started, isNotEmpty);
      expect(recordHeld(started.first, by: milica, now: seededAt), isA<Success<Lesson>>());
    });

    test('Ana can still cancel one confirmed lesson and is too late for another', () async {
      final confirmed = (await lessons.lessonsOf(ana.id)).where((lesson) => lesson.status is Confirmed);
      final outcomes = [for (final lesson in confirmed) cancelLesson(lesson, by: ana, now: seededAt)];

      expect(outcomes.whereType<Success<Lesson>>(), isNotEmpty);
      expect(outcomes, contains(const Failure<Lesson>(CancellationTooLate(notice: cancellationNotice))));
    });

    test('Nikola, the second student account, has lessons too', () async {
      final his = await lessons.lessonsOf(nikola.id);

      expect({for (final lesson in his) lesson.status.runtimeType}, containsAll([Pending, Rejected]));
    });
  });
}
