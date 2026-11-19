@Tags(['db'])
library;

import 'dart:io';

import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Sql;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/fixture.dart';
import 'support/test_database.dart';

const ana = User(id: UserId('ana'), name: 'Ana Jovanović', role: Role.student);
const milica = User(id: UserId('milica'), name: 'Milica Petrović', role: Role.professor);

/// One lucky interleaving proves nothing, so every race runs this many times, each from a fresh fixture.
const rounds = 20;

/// How long the later requests wait before starting, swept over the rounds: 0, 1, 2, 3, 4 ms, then again.
/// At 0 ms both start at the same instant. A few ms let the first get further (read, lock, write) before the
/// other arrives. Each offset gives another interleaving, and the rule has to hold in every one of them.
Duration offset(int round) => Duration(milliseconds: round % 5);

Future<T> after<T>(Duration delay, Future<T> Function() work) => Future.delayed(delay, work);

/// Well before slot s-1 (2026-12-01 10:00), so confirming and withdrawing are both allowed.
final class FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 11, 19, 12);
}

/// The concurrent rule KT2 asks for, decided by the server: **one confirmed lesson per slot**, and a withdrawal
/// racing a confirmation. The real use cases run over Postgres at the same moment (`Future.wait` puts them on
/// separate pool connections), and the database decides who wins: the conditional
/// `UPDATE … WHERE status = 'pending'`, the `FOR UPDATE` lock in `saveConfirmation`, and the partial unique index.
void main() {
  late Database database;
  late PostgresLessons lessons;
  final clock = FixedClock();

  setUpAll(() async {
    database = await createTestDatabase();
    lessons = PostgresLessons(database);
  });
  tearDownAll(() => database.close());

  /// Fresh fixture plus one pending request on s-1 per student, loaded back as the client would have them.
  Future<List<Lesson>> freshRequests(List<String> students) async {
    await truncateTables(database);
    await insertFixture(database);
    for (final student in students) {
      await insertLesson(database, 'l-$student', slot: 's-1', student: student);
    }
    return [for (final student in students) (await lessons.find(LessonId('l-$student')))!];
  }

  /// lesson id → `status` or `status/cause`, as stored.
  Future<Map<String, String>> storedOnSlot(String slot) => database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT id, status, rejection_cause FROM lessons WHERE slot_id = @slot'),
      parameters: {'slot': slot},
    );
    return {for (final row in rows) row[0]! as String: row[2] == null ? '${row[1]}' : '${row[1]}/${row[2]}'};
  });

  test('three confirmations of one slot at the same moment: exactly one wins', () async {
    final losses = <Type, int>{};
    for (var round = 1; round <= rounds; round++) {
      // Milica has the backoffice open in three windows and confirms all three requests at once.
      final requests = await freshRequests(['ana', 'nikola', 'marija']);

      final results = await Future.wait([
        for (var i = 0; i < requests.length; i++)
          after(offset(round) * i, () => ConfirmLesson(lessons, clock, milica)(requests[i])),
      ]);

      final why = 'round $round: $results';
      final winners = results.whereType<Success<Confirmation>>().toList();
      expect(winners, hasLength(1), reason: why);
      expect(winners.single.value.rejected, hasLength(2), reason: why);
      for (final loser in results.whereType<Failure<Confirmation>>()) {
        // LessonChanged: it waited on the lock, then found its request already rejected by the winner.
        // SlotTaken: it read the slot only after the winner had committed.
        expect(loser.error, anyOf(isA<LessonChanged>(), isA<SlotTaken>()), reason: why);
        losses.update(loser.error.runtimeType, (n) => n + 1, ifAbsent: () => 1);
      }

      final stored = await storedOnSlot('s-1');
      final winner = winners.single.value.confirmed.id.value;
      expect(stored, {
        for (final request in requests)
          request.id.value: request.id.value == winner ? 'confirmed' : 'rejected/slot_taken',
      }, reason: why);
    }
    stdout.writeln('3 confirmations x $rounds rounds: one winner each time; the losers got $losses');
  });

  test('a confirmation and a withdrawal of the same request at the same moment: exactly one wins', () async {
    var confirmWon = 0;
    var withdrawWon = 0;
    for (var round = 1; round <= rounds; round++) {
      // Milica confirms Ana's request in the backoffice while Ana withdraws it on her phone.
      final request = (await freshRequests(['ana'])).single;

      final results = await Future.wait<Result<Object>>([
        ConfirmLesson(lessons, clock, milica)(request),
        after(offset(round), () => WithdrawRequest(lessons, clock, ana)(request)),
      ]);

      final why = 'round $round: $results';
      final confirmed = results[0];
      final withdrawn = results[1];
      expect([confirmed.isSuccess, withdrawn.isSuccess].where((won) => won), hasLength(1), reason: why);
      final loser = confirmed.isSuccess ? withdrawn : confirmed;
      expect(loser.errorOrNull, const LessonChanged(), reason: why);

      // The database agrees with whoever won.
      final stored = await storedOnSlot('s-1');
      expect(stored, {'l-ana': confirmed.isSuccess ? 'confirmed' : 'cancelled'}, reason: why);
      if (confirmed.isSuccess) {
        confirmWon++;
      } else {
        withdrawWon++;
      }
    }
    stdout.writeln('confirm vs withdraw x $rounds rounds: confirm won $confirmWon, withdraw won $withdrawWon');
  });
}
