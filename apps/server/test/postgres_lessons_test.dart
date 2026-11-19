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
const nikola = User(id: UserId('nikola'), name: 'Nikola Ilić', role: Role.student);
const marija = User(id: UserId('marija'), name: 'Marija Stojanović', role: Role.student);
const milica = User(id: UserId('milica'), name: 'Milica Petrović', role: Role.professor);

/// Over a week before every fixture slot, so requests pass the 24 h rule and nothing has started yet.
final clockNow = DateTime.utc(2026, 11, 19, 12);

final class FixedClock implements Clock {
  @override
  DateTime now() => clockNow;
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

  group('writes', () {
    Future<Lesson> load(String id) async => (await lessons.find(LessonId(id)))!;
    Future<Object?> statusOf(String id) => column(LessonId(id), 'status');

    /// What Milica's screen would send: a confirmation built from the requests it loaded earlier.
    Future<Confirmation> confirmationSeenNow(String id) async {
      final lesson = await load(id);
      final competing = await lessons.lessonsForSlot(lesson.slotId);
      return confirmLesson(lesson, by: milica, competing: competing, now: clockNow).valueOrNull!;
    }

    test('a withdrawal and a rejection by the professor are stored', () async {
      await insertLesson(database, 'ana-math');
      await insertLesson(database, 'nikola-math', student: 'nikola');

      final withdrawn = await WithdrawRequest(lessons, FixedClock(), ana)(await load('ana-math'));
      final refused = await RejectLesson(lessons, FixedClock(), milica)(await load('nikola-math'));

      expect(await load('ana-math'), withdrawn.valueOrNull);
      expect((await load('ana-math')).status, Cancelled(by: ana.id, at: clockNow));
      expect(await load('nikola-math'), refused.valueOrNull);
      expect(await column(const LessonId('nikola-math'), 'rejection_cause'), 'by_professor');
    });

    test('a held lesson keeps its note', () async {
      await insertLesson(database, 'ana-exam', slot: 's-3', status: 'confirmed', statusAt: requestedAt);
      final confirmed = await load('ana-exam');
      final held = confirmed.copyWith(
        status: Held(at: DateTime.utc(2026, 11, 30, 17, 30), note: LessonNote.parse('Integrali i redovi.').valueOrNull),
      );

      expect(await lessons.save(held, from: confirmed.status), Success(held));
      expect(await load('ana-exam'), held);
    });

    test('a write from a stale status is LessonChanged and changes nothing', () async {
      await insertLesson(database, 'ana-math');
      final seenByMilica = await load('ana-math');
      await WithdrawRequest(lessons, FixedClock(), ana)(await load('ana-math'));

      final result = await RejectLesson(lessons, FixedClock(), milica)(seenByMilica);

      expect(result, const Failure<Lesson>(LessonChanged()));
      expect((await load('ana-math')).status, Cancelled(by: ana.id, at: clockNow));
    });

    test('a save that would confirm a second lesson for one slot is SlotTaken', () async {
      await insertLesson(database, 'ana-math', status: 'confirmed', statusAt: requestedAt);
      await insertLesson(database, 'nikola-math', student: 'nikola');
      final pending = await load('nikola-math');

      final result = await lessons.save(
        pending.copyWith(status: Confirmed(at: clockNow)),
        from: const Pending(),
      );

      expect(result, const Failure<Lesson>(SlotTaken()));
      expect(await statusOf('nikola-math'), 'pending');
    });

    test('a confirmation confirms one request and rejects the other requests for that slot', () async {
      await insertLesson(database, 'ana-math');
      await insertLesson(database, 'nikola-math', student: 'nikola');
      await insertLesson(database, 'marija-math', student: 'marija');
      await insertLesson(database, 'ana-later', slot: 's-2');

      final result = await ConfirmLesson(lessons, FixedClock(), milica)(await load('ana-math'));

      final confirmation = result.valueOrNull!;
      expect(await load('ana-math'), confirmation.confirmed);
      expect(idsOf(confirmation.rejected), ['marija-math', 'nikola-math']);
      expect((await load('nikola-math')).status, Rejected(cause: RejectionCause.slotTaken, at: clockNow));
      expect((await load('marija-math')).status, Rejected(cause: RejectionCause.slotTaken, at: clockNow));
      expect(await statusOf('ana-later'), 'pending');
    });

    test('a student who withdrew in the meantime is skipped and left out of the result', () async {
      await insertLesson(database, 'ana-math');
      await insertLesson(database, 'nikola-math', student: 'nikola');
      await insertLesson(database, 'marija-math', student: 'marija');
      final confirmation = await confirmationSeenNow('ana-math');
      await WithdrawRequest(lessons, FixedClock(), marija)(await load('marija-math'));

      final result = await lessons.saveConfirmation(confirmation);

      expect(idsOf(result.valueOrNull!.rejected), ['nikola-math']);
      expect((await load('marija-math')).status, Cancelled(by: marija.id, at: clockNow));
    });

    test('confirming a second lesson for a taken slot is SlotTaken, and nothing is written', () async {
      await insertLesson(database, 'ana-math');
      await insertLesson(database, 'marija-math', student: 'marija');
      final confirmation = await confirmationSeenNow('ana-math');
      // The database is the last line: however Nikola's lesson got confirmed, a second one never commits.
      await insertLesson(database, 'nikola-math', student: 'nikola', status: 'confirmed', statusAt: clockNow);

      final result = await lessons.saveConfirmation(confirmation);

      expect(result, const Failure<Confirmation>(SlotTaken()));
      expect(await statusOf('ana-math'), 'pending');
      expect(await statusOf('marija-math'), 'pending');
    });

    test('when the lesson to confirm is no longer pending, it is LessonChanged, and nothing is written', () async {
      await insertLesson(database, 'ana-math');
      await insertLesson(database, 'nikola-math', student: 'nikola');
      final confirmation = await confirmationSeenNow('ana-math');
      await WithdrawRequest(lessons, FixedClock(), ana)(await load('ana-math'));

      final result = await lessons.saveConfirmation(confirmation);

      expect(result, const Failure<Confirmation>(LessonChanged()));
      expect(await statusOf('nikola-math'), 'pending');
    });
  });
}
