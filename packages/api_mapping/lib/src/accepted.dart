import 'package:domain/domain.dart';

/// The value of a domain `parse` that a DTO carried. A value the domain refuses means the other side sent bad
/// data: a [FormatException], which the server answers with 400 and the client turns into a repository failure.
T accepted<T>(Result<T> parsed) => switch (parsed) {
  Success(:final value) => value,
  Failure(:final error) => throw FormatException('The contract carried a value the domain refuses: $error'),
};

/// An enum value by its name, or a [FormatException] for a name this side does not know.
T byName<T extends Enum>(List<T> values, String name) => values.firstWhere(
  (value) => value.name == name,
  orElse: () => throw FormatException('Unknown ${T.toString()}', name),
);

LessonDuration durationOf(int minutes) => LessonDuration.values.firstWhere(
  (duration) => duration.minutes == minutes,
  orElse: () => throw FormatException('No lesson lasts $minutes minutes', minutes),
);
