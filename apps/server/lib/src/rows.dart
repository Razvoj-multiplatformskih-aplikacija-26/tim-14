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

/// The `verification` column's value for each state, as the migration's CHECK allows. A switch over a sealed
/// class: a new state would not compile until it gets a name here.
String verificationNameOf(VerificationStatus status) => switch (status) {
  NotVerified() => 'not_verified',
  AwaitingReview() => 'awaiting_review',
  Verified() => 'verified',
  VerificationRejected() => 'rejected',
};

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

/// The writing side of [_verificationFromColumns]: the seven verification columns of a profile, as SQL
/// parameters named after the columns. A column the state does not have is NULL.
Map<String, Object?> verificationParameters(VerificationStatus status) {
  DateTime? submittedAt;
  String? diplomaFile;
  String? linkedIn;
  String? decidedBy;
  DateTime? decidedAt;
  String? reason;
  if (status is AwaitingReview) {
    submittedAt = status.submittedAt;
    diplomaFile = status.diplomaFile;
    linkedIn = status.linkedIn.value;
  } else if (status is Verified) {
    decidedBy = status.by.value;
    decidedAt = status.at;
  } else if (status is VerificationRejected) {
    decidedBy = status.by.value;
    decidedAt = status.at;
    reason = status.reason.text;
  }
  return {
    'verification': verificationNameOf(status),
    'submitted_at': submittedAt,
    'diploma_file': diplomaFile,
    'linkedin_url': linkedIn,
    'decided_by': decidedBy,
    'decided_at': decidedAt,
    'rejection_reason': reason,
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

const lessonColumns = '''
  id, slot_id, listing_id, professor_id, student_id, starts_at, duration_minutes, message, created_at,
  status, status_at, rejection_cause, cancelled_by, note''';

Lesson lessonFromRow(ResultRow row) {
  final column = row.toColumnMap();
  return Lesson(
    id: LessonId(column['id'] as String),
    slotId: SlotId(column['slot_id'] as String),
    listingId: ListingId(column['listing_id'] as String),
    professorId: UserId(column['professor_id'] as String),
    studentId: UserId(column['student_id'] as String),
    start: _utc(column['starts_at']),
    duration: durationOf(column['duration_minutes'] as int),
    message: stored(RequestMessage.parse(column['message'] as String)),
    createdAt: _utc(column['created_at']),
    status: _lessonStatusFromColumns(column),
  );
}

/// Like the verification: `status` says which state, the other four columns hold its fields.
LessonStatus _lessonStatusFromColumns(Map<String, dynamic> column) {
  final status = column['status'] as String;
  if (status == 'pending') {
    return const Pending();
  }
  final at = _utc(column['status_at']);
  return switch (status) {
    'confirmed' => Confirmed(at: at),
    'rejected' => Rejected(cause: _causeFromName(column['rejection_cause'] as String), at: at),
    'cancelled' => Cancelled(by: UserId(column['cancelled_by'] as String), at: at),
    'held' => Held(at: at, note: column['note'] == null ? null : stored(LessonNote.parse(column['note'] as String))),
    'no_show' => NoShow(at: at),
    _ => throw StateError('Unknown lesson status $status'),
  };
}

/// The `rejection_cause` column's value, the same name the JSON uses.
String rejectionCauseNameOf(RejectionCause cause) => switch (cause) {
  RejectionCause.byProfessor => 'by_professor',
  RejectionCause.slotTaken => 'slot_taken',
};

RejectionCause _causeFromName(String name) => switch (name) {
  'by_professor' => RejectionCause.byProfessor,
  'slot_taken' => RejectionCause.slotTaken,
  _ => throw StateError('Unknown rejection cause $name'),
};

/// The `status` column's value for each state, as the migration's CHECK allows.
String lessonStatusNameOf(LessonStatus status) => switch (status) {
  Pending() => 'pending',
  Confirmed() => 'confirmed',
  Rejected() => 'rejected',
  Cancelled() => 'cancelled',
  Held() => 'held',
  NoShow() => 'no_show',
};

/// The other way: the five status columns of a lesson, as SQL parameters named after the columns.
/// A column the status does not have is NULL, so writing a new status also clears the old one's fields.
Map<String, Object?> lessonStatusParameters(LessonStatus status) {
  DateTime? at;
  String? cause;
  String? cancelledBy;
  String? note;
  if (status is Confirmed) {
    at = status.at;
  } else if (status is Rejected) {
    at = status.at;
    cause = rejectionCauseNameOf(status.cause);
  } else if (status is Cancelled) {
    at = status.at;
    cancelledBy = status.by.value;
  } else if (status is Held) {
    at = status.at;
    note = status.note?.text;
  } else if (status is NoShow) {
    at = status.at;
  }
  return {
    'status': lessonStatusNameOf(status),
    'status_at': at,
    'rejection_cause': cause,
    'cancelled_by': cancelledBy,
    'note': note,
  };
}
