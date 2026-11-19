import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Session, Sql;
import 'package:use_cases/use_cases.dart';

import 'database.dart';
import 'rows.dart';

/// [LessonRepository] over Postgres.
final class PostgresLessons implements LessonRepository {
  PostgresLessons(this._database);

  final Database _database;

  @override
  Future<List<Lesson>> lessonsOf(UserId student) => _lessonsWhere('student_id', student.value);

  @override
  Future<List<Lesson>> lessonsForSlot(SlotId slot) => _lessonsWhere('slot_id', slot.value);

  @override
  Future<List<Lesson>> lessonsOfProfessor(UserId professor) => _lessonsWhere('professor_id', professor.value);

  /// [column] is always one of the constants above, never input, so it may go into the SQL text.
  /// The value goes in as a parameter.
  Future<List<Lesson>> _lessonsWhere(String column, String value) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $lessonColumns FROM lessons WHERE $column = @value ORDER BY starts_at, id'),
      parameters: {'value': value},
    );
    return [for (final row in rows) lessonFromRow(row)];
  });

  /// Only the slot ids that already have a confirmed lesson. Other students' requests and messages never
  /// leave the database. "Taken" means the same as in the unique index: a confirmed lesson.
  @override
  Future<Set<SlotId>> takenSlotsOf(UserId professor) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named("SELECT slot_id FROM lessons WHERE professor_id = @professor AND status = 'confirmed'"),
      parameters: {'professor': professor.value},
    );
    return {for (final row in rows) SlotId(row.single! as String)};
  });

  @override
  Future<Lesson?> find(LessonId id) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $lessonColumns FROM lessons WHERE id = @id'),
      parameters: {'id': id.value},
    );
    return rows.isEmpty ? null : lessonFromRow(rows.single);
  });

  /// A random UUID from Postgres. The id exists before the row, because `requestLesson` builds the lesson first.
  @override
  Future<LessonId> nextId() => _database.run((db) async {
    final rows = await db.execute('SELECT gen_random_uuid()::text');
    return LessonId(rows.single.single! as String);
  });

  /// Inserts a new request. Both names are copied from `users` at this moment, a snapshot like the slot's time:
  /// a later rename does not rewrite old lessons. (Until Ilija's I1 puts the names on `Lesson` itself.)
  @override
  Future<Result<Lesson>> create(Lesson lesson) => _database.run((db) async {
    await db.execute(
      Sql.named('''
        INSERT INTO lessons (id, slot_id, listing_id, professor_id, professor_name, student_id, student_name,
                             starts_at, duration_minutes, message, created_at,
                             status, status_at, rejection_cause, cancelled_by, note)
        VALUES (@id, @slot, @listing, @professor, (SELECT name FROM users WHERE id = @professor),
                @student, (SELECT name FROM users WHERE id = @student),
                @start:timestamptz, @duration, @message, @created_at:timestamptz,
                @status, @status_at:timestamptz, @rejection_cause, @cancelled_by, @note)'''),
      parameters: {
        'id': lesson.id.value,
        'slot': lesson.slotId.value,
        'listing': lesson.listingId.value,
        'professor': lesson.professorId.value,
        'student': lesson.studentId.value,
        'start': lesson.start,
        'duration': lesson.duration.minutes,
        'message': lesson.message.text,
        'created_at': lesson.createdAt,
        ...lessonStatusParameters(lesson.status),
      },
    );
    return Success(lesson);
  });

  /// Writes the new status only if the lesson still has the status [from], the one the caller saw.
  ///
  /// 0 rows: someone changed the lesson first (the student withdrew, the professor already decided), so
  /// nothing is written and the caller gets [LessonChanged]. Run as a transaction so that the database's
  /// "one confirmed lesson per slot" refusal (23505) comes back as [SlotTaken], not as a 500.
  @override
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from}) => _database.transaction((tx) async {
    if (!await _writeStatus(tx, lesson, from: from)) {
      return const Failure(LessonChanged());
    }
    return Success(lesson);
  });

  /// The confirmation and its auto-rejections commit together or not at all.
  ///
  /// 1. Lock every request for the slot, in id order. A second confirmation of the same slot waits on this
  ///    line until the first one commits. Without it, two confirmations could each hold a row the other one
  ///    needs (deadlock, which Postgres ends by killing one of them).
  /// 2. Confirm, if still pending. If not, nothing is written: [LessonChanged].
  /// 3. Reject each competitor that is still pending. One that is not (the student withdrew in the meantime)
  ///    is skipped and left out of the returned list.
  ///
  /// A second confirmed lesson for the slot is refused by the unique index (23505): [SlotTaken], all rolled back.
  @override
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation) => _database.transaction((tx) async {
    final confirmed = confirmation.confirmed;
    await tx.execute(
      Sql.named('SELECT id FROM lessons WHERE slot_id = @slot ORDER BY id FOR UPDATE'),
      parameters: {'slot': confirmed.slotId.value},
    );

    if (!await _writeStatus(tx, confirmed, from: const Pending())) {
      return const Failure(LessonChanged());
    }

    final rejected = <Lesson>[];
    for (final other in confirmation.rejected) {
      if (await _writeStatus(tx, other, from: const Pending())) {
        rejected.add(other);
      }
    }
    return Success(Confirmation(confirmed: confirmed, rejected: rejected));
  });

  /// The conditional UPDATE both writes use. True if the row changed, false if its status was no longer [from].
  Future<bool> _writeStatus(Session db, Lesson lesson, {required LessonStatus from}) async {
    final changed = await db.execute(
      Sql.named('''
        UPDATE lessons
        SET status = @status, status_at = @status_at:timestamptz, rejection_cause = @rejection_cause,
            cancelled_by = @cancelled_by, note = @note
        WHERE id = @id AND status = @from'''),
      parameters: {...lessonStatusParameters(lesson.status), 'id': lesson.id.value, 'from': lessonStatusNameOf(from)},
    );
    return changed.affectedRows == 1;
  }
}
