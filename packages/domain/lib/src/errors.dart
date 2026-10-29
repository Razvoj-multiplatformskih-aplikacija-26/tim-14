import 'package:meta/meta.dart';

import 'lesson/lesson_status.dart';
import 'professor/verification_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class InvalidRequestMessage extends DomainError {
  const InvalidRequestMessage(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is InvalidRequestMessage && other.length == length;

  @override
  int get hashCode => Object.hash(InvalidRequestMessage, length);

  @override
  String toString() => 'InvalidRequestMessage($length)';
}

@immutable
final class NoteTooLong extends DomainError {
  const NoteTooLong(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is NoteTooLong && other.length == length;

  @override
  int get hashCode => Object.hash(NoteTooLong, length);

  @override
  String toString() => 'NoteTooLong($length)';
}

@immutable
final class ReviewTextTooLong extends DomainError {
  const ReviewTextTooLong(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is ReviewTextTooLong && other.length == length;

  @override
  int get hashCode => Object.hash(ReviewTextTooLong, length);

  @override
  String toString() => 'ReviewTextTooLong($length)';
}

@immutable
final class InvalidRating extends DomainError {
  const InvalidRating(this.value);

  final int value;

  @override
  bool operator ==(Object other) => other is InvalidRating && other.value == value;

  @override
  int get hashCode => Object.hash(InvalidRating, value);

  @override
  String toString() => 'InvalidRating($value)';
}

@immutable
final class InvalidPrice extends DomainError {
  const InvalidPrice(this.dinars);

  final int dinars;

  @override
  bool operator ==(Object other) => other is InvalidPrice && other.dinars == dinars;

  @override
  int get hashCode => Object.hash(InvalidPrice, dinars);

  @override
  String toString() => 'InvalidPrice($dinars)';
}

final class InvalidLinkedInUrl extends DomainError {
  const InvalidLinkedInUrl();
}

final class MissingRejectionReason extends DomainError {
  const MissingRejectionReason();
}

final class SlotInPast extends DomainError {
  const SlotInPast();
}

final class SlotNotOnHalfHour extends DomainError {
  const SlotNotOnHalfHour();
}

final class SlotOverlaps extends DomainError {
  const SlotOverlaps();
}

final class TooSoonToRequest extends DomainError {
  const TooSoonToRequest();
}

final class TooManyPendingRequests extends DomainError {
  const TooManyPendingRequests();
}

final class AlreadyRequested extends DomainError {
  const AlreadyRequested();
}

final class SlotTaken extends DomainError {
  const SlotTaken();
}

final class LessonStarted extends DomainError {
  const LessonStarted();
}

final class LessonNotStarted extends DomainError {
  const LessonNotStarted();
}

final class CancellationTooLate extends DomainError {
  const CancellationTooLate();
}

@immutable
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final LessonStatus from;
  final LessonStatus to;

  @override
  bool operator ==(Object other) =>
      other is InvalidTransition &&
      other.from.runtimeType == from.runtimeType &&
      other.to.runtimeType == to.runtimeType;

  @override
  int get hashCode => Object.hash(InvalidTransition, from.runtimeType, to.runtimeType);

  @override
  String toString() => 'InvalidTransition(${from.runtimeType} -> ${to.runtimeType})';
}

final class LessonNotHeld extends DomainError {
  const LessonNotHeld();
}

final class AlreadyReviewed extends DomainError {
  const AlreadyReviewed();
}

@immutable
final class InvalidVerificationTransition extends DomainError {
  const InvalidVerificationTransition({required this.from, required this.to});

  final VerificationStatus from;
  final VerificationStatus to;

  @override
  bool operator ==(Object other) =>
      other is InvalidVerificationTransition &&
      other.from.runtimeType == from.runtimeType &&
      other.to.runtimeType == to.runtimeType;

  @override
  int get hashCode => Object.hash(InvalidVerificationTransition, from.runtimeType, to.runtimeType);

  @override
  String toString() => 'InvalidVerificationTransition(${from.runtimeType} -> ${to.runtimeType})';
}

final class NotAllowed extends DomainError {
  const NotAllowed();
}

final class NotFound extends DomainError {
  const NotFound();
}

final class LessonChanged extends DomainError {
  const LessonChanged();
}
