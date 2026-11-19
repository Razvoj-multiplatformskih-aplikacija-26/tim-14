@Tags(['db'])
library;

import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Sql;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/fixture.dart';
import 'support/test_database.dart';

const ana = User(id: UserId('ana'), name: 'Ana Jovanović', role: Role.student);

/// Two weeks before slot s-1, so a request for it passes the 24 h rule.
final class FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 11, 19, 12);
}

void main() {
  late Database database;
  late PostgresLessons lessons;
  late PostgresProfessors professors;

  setUpAll(() async {
    database = await createTestDatabase();
    lessons = PostgresLessons(database);
    professors = PostgresProfessors(database);
  });
  setUp(() async {
    await truncateTables(database);
    await insertFixture(database);
  });
  tearDownAll(() => database.close());

  Future<Object?> column(LessonId id, String name) => database.run(
    (db) async => (await db.execute(
      Sql.named('SELECT $name FROM lessons WHERE id = @id'),
      parameters: {'id': id.value},
    )).single.single,
  );

  List<String> idsOf(List<Lesson> list) => [for (final lesson in list) lesson.id.value];

  test('a request goes in through RequestLesson and reads back equal, with both names copied', () async {
    final slot = (await professors.findSlot(const SlotId('s-1')))!;

    final result = await RequestLesson(lessons, FixedClock(), ana)(slot: slot, text: requestText);

    final created = result.valueOrNull!;
    expect(await lessons.find(created.id), created);
    expect(created.status, const Pending());
    expect(await column(created.id, 'student_name'), 'Ana Jovanović');
    expect(await column(created.id, 'professor_name'), 'Milica Petrović');
  });

  test('nextId is a new UUID every time', () async {
    final first = await lessons.nextId();
    final second = await lessons.nextId();

    expect(first, isNot(second));
    expect(first.value, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
  });

  test('find of an unknown id is null', () async {
    expect(await lessons.find(const LessonId('nope')), isNull);
  });

  test('each list read filters by its own column, earliest first', () async {
    await insertLesson(database, 'ana-physics', slot: 's-4');
    await insertLesson(database, 'ana-math', slot: 's-1');
    await insertLesson(database, 'nikola-math', slot: 's-1', student: 'nikola');
    await insertLesson(database, 'nikola-exam', slot: 's-3', student: 'nikola');

    expect(idsOf(await lessons.lessonsOf(const UserId('ana'))), ['ana-math', 'ana-physics']);
    expect(idsOf(await lessons.lessonsOfProfessor(const UserId('jovan'))), ['ana-physics']);
    expect(idsOf(await lessons.lessonsOfProfessor(const UserId('milica'))), ['nikola-exam', 'ana-math', 'nikola-math']);
    expect(idsOf(await lessons.lessonsForSlot(const SlotId('s-1'))), ['ana-math', 'nikola-math']);
  });

  test('a row in each status reads back as that LessonStatus', () async {
    final at = DateTime.utc(2026, 11, 18, 10, 0, 0, 0, 250);
    await insertLesson(database, 'pending');
    await insertLesson(database, 'confirmed', slot: 's-2', status: 'confirmed', statusAt: at);
    await insertLesson(
      database,
      'auto-rejected',
      slot: 's-2',
      student: 'nikola',
      status: 'rejected',
      statusAt: at,
      cause: 'slot_taken',
    );
    await insertLesson(database, 'refused', student: 'nikola', status: 'rejected', statusAt: at, cause: 'by_professor');
    await insertLesson(database, 'cancelled', slot: 's-3', status: 'cancelled', statusAt: at, cancelledBy: 'milica');
    await insertLesson(
      database,
      'held',
      slot: 's-3',
      student: 'nikola',
      status: 'held',
      statusAt: at,
      note: 'Integrali.',
    );
    await insertLesson(database, 'held-no-note', slot: 's-4', status: 'held', statusAt: at);
    await insertLesson(database, 'no-show', slot: 's-3', student: 'marija', status: 'no_show', statusAt: at);

    Future<LessonStatus> statusOf(String id) async => (await lessons.find(LessonId(id)))!.status;

    expect(await statusOf('pending'), const Pending());
    expect(await statusOf('confirmed'), Confirmed(at: at));
    expect(await statusOf('auto-rejected'), Rejected(cause: RejectionCause.slotTaken, at: at));
    expect(await statusOf('refused'), Rejected(cause: RejectionCause.byProfessor, at: at));
    expect(await statusOf('cancelled'), Cancelled(by: const UserId('milica'), at: at));
    expect(await statusOf('held'), Held(at: at, note: LessonNote.parse('Integrali.').valueOrNull));
    expect(await statusOf('held-no-note'), Held(at: at));
    expect(await statusOf('no-show'), NoShow(at: at));
  });

  test('takenSlotsOf is only the professor’s slots with a confirmed lesson', () async {
    final at = DateTime.utc(2026, 11, 18, 10);
    await insertLesson(database, 'waiting', slot: 's-1');
    await insertLesson(database, 'confirmed', slot: 's-2', status: 'confirmed', statusAt: at);
    await insertLesson(database, 'refused', slot: 's-3', status: 'rejected', statusAt: at, cause: 'by_professor');
    await insertLesson(database, 'other-professor', slot: 's-4', status: 'confirmed', statusAt: at);

    expect(await lessons.takenSlotsOf(const UserId('milica')), {const SlotId('s-2')});
  });
}
