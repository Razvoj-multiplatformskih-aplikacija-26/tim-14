import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Sql;
import 'package:use_cases/use_cases.dart';

import 'database.dart';
import 'rows.dart';

/// [VerificationRepository] over Postgres. Reads profiles with the same mapper as [ProfessorRepository]'s
/// adapter, and saves an admin's decision with one conditional UPDATE.
final class PostgresVerifications implements VerificationRepository {
  PostgresVerifications(this._database);

  final Database _database;

  /// Only the profiles that wait for a decision, the longest-waiting first. `GetVerificationQueue` filters
  /// and sorts again, which changes nothing here.
  @override
  Future<List<ProfessorProfile>> queue() => _database.run((db) async {
    final rows = await db.execute(
      "SELECT $profileColumns FROM $profileTables WHERE p.verification = 'awaiting_review' "
      'ORDER BY p.submitted_at, p.user_id',
    );
    return [for (final row in rows) profileFromRow(row)];
  });

  @override
  Future<ProfessorProfile?> find(UserId professor) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $profileColumns FROM $profileTables WHERE p.user_id = @id'),
      parameters: {'id': professor.value},
    );
    return rows.isEmpty ? null : profileFromRow(rows.single);
  });

  /// Writes the decision only if the profile still has the status [from], the one the admin saw.
  ///
  /// Two admins decide the same profile: the first UPDATE changes 1 row. The second one's `WHERE verification
  /// = @from` no longer matches, so it changes 0 rows and nothing is written. If both run at the same moment,
  /// Postgres locks the row for the first; the second waits, then checks its WHERE against the committed row.
  /// One statement on one row, so no transaction is needed.
  @override
  Future<Result<ProfessorProfile>> save(ProfessorProfile profile, {required VerificationStatus from}) async {
    final next = profile.verification;
    final UserId by;
    final DateTime at;
    String? reason;
    if (next is Verified) {
      by = next.by;
      at = next.at;
    } else if (next is VerificationRejected) {
      by = next.by;
      at = next.at;
      reason = next.reason.text;
    } else {
      throw ArgumentError.value(next, 'profile.verification', 'Only an admin decision is saved here');
    }

    final changed = await _database.run(
      (db) => db.execute(
        Sql.named('''
          UPDATE professor_profiles
          SET verification = @next, decided_by = @by, decided_at = @at:timestamptz, rejection_reason = @reason
          WHERE user_id = @id AND verification = @from'''),
        parameters: {
          'next': verificationNameOf(next),
          'by': by.value,
          'at': at,
          'reason': reason,
          'id': profile.id.value,
          'from': verificationNameOf(from),
        },
      ),
    );
    if (changed.affectedRows == 1) {
      return Success(profile);
    }

    // 0 rows: either there is no such profile, or someone decided first. Say which, with what is there now.
    final current = await find(profile.id);
    if (current == null) {
      return const Failure(NotFound());
    }
    return Failure(InvalidVerificationTransition(from: current.verification, to: next));
  }
}
