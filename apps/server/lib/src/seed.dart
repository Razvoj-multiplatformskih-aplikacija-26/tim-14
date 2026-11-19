import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Session, Sql, TxSession;

import 'database.dart';
import 'demo_data.dart';
import 'passwords.dart';
import 'postgres_lessons.dart' show insertLessonRow;
import 'rows.dart';

enum SeedOutcome {
  /// The database was empty and now holds the demo data.
  seeded,

  /// The database already had users, so nothing was written. A restart keeps whatever the demo changed.
  notEmpty,

  /// `DEMO_PASSWORD` is not set. A deployment that wants no demo accounts leaves it out.
  noDemoPassword,
}

/// Writes [demoData] into an empty database, with every login's password hashed from [demoPassword].
///
/// All rows go in one transaction. A seed that failed halfway would leave some users behind, and the "already
/// has users" check would then skip the seed on every later start, so it is all or nothing.
Future<SeedOutcome> seedIfEmpty(Database database, {required String? demoPassword, required DateTime now}) async {
  if (demoPassword == null) {
    return SeedOutcome.noDemoPassword;
  }
  // Checked once before hashing, so an ordinary restart doesn't spend a second on Argon2.
  if (await database.run(_hasUsers)) {
    return SeedOutcome.notEmpty;
  }

  final data = demoData(now);
  // Every login gets its own hash: Argon2 draws a new random salt each time, so equal passwords look different.
  final hashes = <UserId, String>{for (final user in data.logins.values) user.id: await hashPassword(demoPassword)};

  final result = await database.transaction((tx) async {
    // Two servers starting at once: the second waits on this lock until the first commits, then finds the users
    // below and writes nothing. Without it both would insert, and the second would crash on a duplicate id.
    await tx.execute('LOCK TABLE users IN EXCLUSIVE MODE');
    if (await _hasUsers(tx)) {
      return const Success(false);
    }
    await _write(tx, data, hashes);
    return const Success(true);
  });

  if (result is Success<bool> && result.value) {
    return SeedOutcome.seeded;
  }
  return SeedOutcome.notEmpty;
}

Future<bool> _hasUsers(Session db) async {
  final rows = await db.execute('SELECT EXISTS (SELECT 1 FROM users)');
  return rows.single.single! as bool;
}

/// One INSERT per row. A few dozen rows once per fresh database, so there is nothing to gain from batching.
/// The order follows the foreign keys: users, then profiles and listings, then slots, then lessons.
Future<void> _write(TxSession tx, DemoData data, Map<UserId, String> passwordHashes) async {
  final loginOf = {for (final entry in data.logins.entries) entry.value.id: entry.key};

  for (final user in data.users) {
    await tx.execute(
      Sql.named('INSERT INTO users (id, name, role, login, password_hash) VALUES (@id, @name, @role, @login, @hash)'),
      parameters: {
        'id': user.id.value,
        'name': user.name,
        'role': user.role.name,
        'login': loginOf[user.id],
        'hash': passwordHashes[user.id],
      },
    );
  }

  for (final profile in data.profiles) {
    await tx.execute(
      Sql.named('''
        INSERT INTO professor_profiles (user_id, city, bio, education, experience, verification,
                                        submitted_at, diploma_file, linkedin_url, decided_by, decided_at, rejection_reason)
        VALUES (@id, @city, @bio, @education:jsonb, @experience:jsonb, @verification,
                @submitted_at:timestamptz, @diploma_file, @linkedin_url, @decided_by, @decided_at:timestamptz,
                @rejection_reason)'''),
      parameters: {
        'id': profile.id.value,
        'city': profile.city.name,
        'bio': profile.bio,
        'education': [
          for (final item in profile.education)
            {'institution': item.institution, 'title': item.title, 'fromYear': item.fromYear, 'toYear': item.toYear},
        ],
        'experience': [
          for (final item in profile.experience)
            {'employer': item.employer, 'title': item.title, 'fromYear': item.fromYear, 'toYear': item.toYear},
        ],
        ...verificationParameters(profile.verification),
      },
    );
  }

  for (final listing in data.listings) {
    await tx.execute(
      Sql.named('''
        INSERT INTO listings (id, professor_id, subject, level, city, description, price_rsd, duration_minutes)
        VALUES (@id, @professor, @subject, @level, @city, @description, @price, @duration)'''),
      parameters: {
        'id': listing.id.value,
        'professor': listing.professorId.value,
        'subject': listing.subject.name,
        'level': listing.level.name,
        'city': listing.city.name,
        'description': listing.description,
        'price': listing.price.dinars,
        'duration': listing.duration.minutes,
      },
    );
  }

  for (final slot in data.slots) {
    await tx.execute(
      Sql.named('''
        INSERT INTO slots (id, listing_id, professor_id, starts_at, duration_minutes)
        VALUES (@id, @listing, @professor, @start:timestamptz, @duration)'''),
      parameters: {
        'id': slot.id.value,
        'listing': slot.listingId.value,
        'professor': slot.professorId.value,
        'start': slot.start,
        'duration': slot.duration.minutes,
      },
    );
  }

  for (final lesson in data.lessons) {
    await insertLessonRow(tx, lesson);
  }
}
