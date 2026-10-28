import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'lesson_note.dart';

sealed class LessonStatus {
  const LessonStatus();

  bool get isFinal => switch (this) {
    Pending() || Confirmed() => false,
    Rejected() || Cancelled() || Held() || NoShow() => true,
  };

  bool canTransitionTo(LessonStatus next) => switch ((this, next)) {
    (Pending(), Confirmed() || Rejected() || Cancelled()) => true,
    (Confirmed(), Cancelled() || Held() || NoShow()) => true,
    _ => false,
  };
}

final class Pending extends LessonStatus {
  const Pending();

  @override
  String toString() => 'Pending';
}

@immutable
final class Confirmed extends LessonStatus {
  const Confirmed({required this.at});

  final DateTime at;

  @override
  bool operator ==(Object other) => other is Confirmed && other.at == at;

  @override
  int get hashCode => Object.hash(Confirmed, at);

  @override
  String toString() => 'Confirmed(at $at)';
}

enum RejectionCause { byProfessor, slotTaken }

@immutable
final class Rejected extends LessonStatus {
  const Rejected({required this.cause, required this.at});

  final RejectionCause cause;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Rejected && other.cause == cause && other.at == at;

  @override
  int get hashCode => Object.hash(cause, at);

  @override
  String toString() => 'Rejected(${cause.name} at $at)';
}

@immutable
final class Cancelled extends LessonStatus {
  const Cancelled({required this.by, required this.at});

  final UserId by;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Cancelled && other.by == by && other.at == at;

  @override
  int get hashCode => Object.hash(by, at);

  @override
  String toString() => 'Cancelled(by $by at $at)';
}

@immutable
final class Held extends LessonStatus {
  const Held({required this.at, this.note});

  final DateTime at;
  final LessonNote? note;

  @override
  bool operator ==(Object other) => other is Held && other.at == at && other.note == note;

  @override
  int get hashCode => Object.hash(at, note);

  @override
  String toString() => 'Held(at $at)';
}

@immutable
final class NoShow extends LessonStatus {
  const NoShow({required this.at});

  final DateTime at;

  @override
  bool operator ==(Object other) => other is NoShow && other.at == at;

  @override
  int get hashCode => Object.hash(NoShow, at);

  @override
  String toString() => 'NoShow(at $at)';
}
