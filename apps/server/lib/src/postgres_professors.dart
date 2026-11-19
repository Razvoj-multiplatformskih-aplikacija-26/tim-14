import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Sql;
import 'package:use_cases/use_cases.dart';

import 'database.dart';
import 'http.dart' show RecordNotFound;
import 'rows.dart';

/// [ProfessorRepository] over Postgres. Everything here is a read, so every method goes through [Database.run].
final class PostgresProfessors implements ProfessorRepository {
  PostgresProfessors(this._database);

  final Database _database;

  /// One page of profiles, each with its listings. Asks for one row more than [limit]: if it comes back,
  /// there is a next page. The listings of the whole page come in one query, so a page is two queries
  /// whatever its size (no N+1).
  @override
  Future<ProfessorsPage> professors({int offset = 0, int limit = 20}) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $profileColumns FROM $profileTables ORDER BY u.name, p.user_id LIMIT @limit OFFSET @offset'),
      parameters: {'limit': limit + 1, 'offset': offset},
    );
    final profiles = [for (final row in rows.take(limit)) profileFromRow(row)];

    final listingRows = await db.execute(
      Sql.named('SELECT $listingColumns FROM listings WHERE professor_id = ANY(@ids:_text) ORDER BY id'),
      parameters: {
        'ids': [for (final profile in profiles) profile.id.value],
      },
    );
    final listings = [for (final row in listingRows) listingFromRow(row)];

    return ProfessorsPage(
      items: [
        for (final profile in profiles)
          ProfessorSummary(
            profile: profile,
            listings: [
              for (final listing in listings)
                if (listing.professorId == profile.id) listing,
            ],
          ),
      ],
      nextOffset: rows.length > limit ? offset + limit : null,
    );
  });

  /// The port promises a profile, so an unknown id throws [RecordNotFound], which the server answers with 404.
  @override
  Future<ProfessorProfile> profile(UserId id) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $profileColumns FROM $profileTables WHERE p.user_id = @id'),
      parameters: {'id': id.value},
    );
    if (rows.isEmpty) {
      throw RecordNotFound('No professor $id');
    }
    return profileFromRow(rows.single);
  });

  @override
  Future<List<Listing>> listingsOf(UserId professor) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $listingColumns FROM listings WHERE professor_id = @professor ORDER BY id'),
      parameters: {'professor': professor.value},
    );
    return [for (final row in rows) listingFromRow(row)];
  });

  @override
  Future<List<Slot>> slotsOf(UserId professor) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $slotColumns FROM slots WHERE professor_id = @professor ORDER BY starts_at, id'),
      parameters: {'professor': professor.value},
    );
    return [for (final row in rows) slotFromRow(row)];
  });

  @override
  Future<Slot?> findSlot(SlotId id) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT $slotColumns FROM slots WHERE id = @id'),
      parameters: {'id': id.value},
    );
    return rows.isEmpty ? null : slotFromRow(rows.single);
  });
}
