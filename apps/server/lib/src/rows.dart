import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show ResultRow;

/// Turning database rows into domain objects. In Spring terms each `…FromRow` is a `RowMapper<T>`.
///
/// Rows are not DTOs: what leaves this file is the same domain object the clients use, so the
/// repositories hand the use cases nothing new to learn.

/// A value object read back from the database must parse, because only parsed values were ever written.
/// A [Failure] means a corrupt row: a bug or a hand edit, never the user's fault, so it is a 500.
T stored<T>(Result<T> parsed) {
  if (parsed is Success<T>) {
    return parsed.value;
  }
  throw StateError('A stored value does not parse: ${parsed.errorOrNull}');
}

LessonDuration durationOf(int minutes) => LessonDuration.values.firstWhere(
  (duration) => duration.minutes == minutes,
  orElse: () => throw StateError('No lesson lasts $minutes minutes'),
);

DateTime _utc(Object? value) => (value! as DateTime).toUtc();

/// A `jsonb` array of objects, already decoded by the driver.
List<Map<String, Object?>> _jsonObjects(Object? json) => [
  for (final entry in json! as List<Object?>) entry! as Map<String, Object?>,
];

/// The columns [profileFromRow] reads. A profile is two tables: the name lives on `users`.
const profileColumns = '''
  p.user_id, u.name, p.city, p.bio, p.education, p.experience, p.verification,
  p.submitted_at, p.diploma_file, p.linkedin_url, p.decided_by, p.decided_at, p.rejection_reason''';

const profileTables = 'professor_profiles p JOIN users u ON u.id = p.user_id';

ProfessorProfile profileFromRow(ResultRow row) {
  final column = row.toColumnMap();
  return ProfessorProfile(
    id: UserId(column['user_id'] as String),
    fullName: column['name'] as String,
    city: City.values.byName(column['city'] as String),
    bio: column['bio'] as String,
    education: [
      for (final item in _jsonObjects(column['education']))
        (
          institution: item['institution']! as String,
          title: item['title']! as String,
          fromYear: item['fromYear']! as int,
          toYear: item['toYear'] as int?,
        ),
    ],
    experience: [
      for (final item in _jsonObjects(column['experience']))
        (
          employer: item['employer']! as String,
          title: item['title']! as String,
          fromYear: item['fromYear']! as int,
          toYear: item['toYear'] as int?,
        ),
    ],
    verification: _verificationFromColumns(column),
  );
}

/// The `verification` column says which state. The other columns hold that state's fields.
VerificationStatus _verificationFromColumns(Map<String, dynamic> column) {
  final status = column['verification'] as String;
  return switch (status) {
    'not_verified' => const NotVerified(),
    'awaiting_review' => AwaitingReview(
      submittedAt: _utc(column['submitted_at']),
      diplomaFile: column['diploma_file'] as String,
      linkedIn: stored(LinkedInUrl.parse(column['linkedin_url'] as String)),
    ),
    'verified' => Verified(by: UserId(column['decided_by'] as String), at: _utc(column['decided_at'])),
    'rejected' => VerificationRejected(
      by: UserId(column['decided_by'] as String),
      at: _utc(column['decided_at']),
      reason: stored(RejectionReason.parse(column['rejection_reason'] as String)),
    ),
    _ => throw StateError('Unknown verification status $status'),
  };
}

const listingColumns = 'id, professor_id, subject, level, city, description, price_rsd, duration_minutes';

Listing listingFromRow(ResultRow row) {
  final column = row.toColumnMap();
  return Listing(
    id: ListingId(column['id'] as String),
    professorId: UserId(column['professor_id'] as String),
    subject: Subject.values.byName(column['subject'] as String),
    level: Level.values.byName(column['level'] as String),
    city: City.values.byName(column['city'] as String),
    description: column['description'] as String,
    price: stored(Price.parse(column['price_rsd'] as int)),
    duration: durationOf(column['duration_minutes'] as int),
  );
}

const slotColumns = 'id, listing_id, professor_id, starts_at, duration_minutes';

Slot slotFromRow(ResultRow row) {
  final column = row.toColumnMap();
  return Slot(
    id: SlotId(column['id'] as String),
    listingId: ListingId(column['listing_id'] as String),
    professorId: UserId(column['professor_id'] as String),
    start: _utc(column['starts_at']),
    duration: durationOf(column['duration_minutes'] as int),
  );
}
