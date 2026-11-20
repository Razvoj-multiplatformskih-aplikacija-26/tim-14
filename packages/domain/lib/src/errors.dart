import 'package:meta/meta.dart';

import 'lesson/lesson_status.dart';
import 'professor/verification_status.dart';

sealed class DomainError {
  const DomainError();
}

// Greške pravila sa granicom nose i tu granicu (max, min, notice). Tekst za korisnika čita broj iz greške,
// a ne iz konstante u aplikaciji. Tako i aplikacija napravljena pre izmene pravila na serveru pokaže
// granicu koju je server stvarno primenio.

@immutable
final class InvalidRequestMessage extends DomainError {
  const InvalidRequestMessage(this.length, {required this.max});

  // 0 znači prazna poruka.
  final int length;
  final int max;

  @override
  bool operator ==(Object other) => other is InvalidRequestMessage && other.length == length && other.max == max;

  @override
  int get hashCode => Object.hash(InvalidRequestMessage, length, max);

  @override
  String toString() => 'InvalidRequestMessage($length, max: $max)';
}

@immutable
final class NoteTooLong extends DomainError {
  const NoteTooLong(this.length, {required this.max});

  final int length;
  final int max;

  @override
  bool operator ==(Object other) => other is NoteTooLong && other.length == length && other.max == max;

  @override
  int get hashCode => Object.hash(NoteTooLong, length, max);

  @override
  String toString() => 'NoteTooLong($length, max: $max)';
}

@immutable
final class ReviewTextTooLong extends DomainError {
  const ReviewTextTooLong(this.length, {required this.max});

  final int length;
  final int max;

  @override
  bool operator ==(Object other) => other is ReviewTextTooLong && other.length == length && other.max == max;

  @override
  int get hashCode => Object.hash(ReviewTextTooLong, length, max);

  @override
  String toString() => 'ReviewTextTooLong($length, max: $max)';
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

@immutable
final class RejectionReasonTooShort extends DomainError {
  const RejectionReasonTooShort(this.length, {required this.min});

  final int length;
  final int min;

  @override
  bool operator ==(Object other) => other is RejectionReasonTooShort && other.length == length && other.min == min;

  @override
  int get hashCode => Object.hash(RejectionReasonTooShort, length, min);

  @override
  String toString() => 'RejectionReasonTooShort($length, min: $min)';
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

@immutable
final class TooSoonToRequest extends DomainError {
  const TooSoonToRequest({required this.notice});

  // Koliko ranije termin mora da se zatraži.
  final Duration notice;

  @override
  bool operator ==(Object other) => other is TooSoonToRequest && other.notice == notice;

  @override
  int get hashCode => Object.hash(TooSoonToRequest, notice);

  @override
  String toString() => 'TooSoonToRequest(notice: $notice)';
}

@immutable
final class TooManyPendingRequests extends DomainError {
  const TooManyPendingRequests({required this.max});

  final int max;

  @override
  bool operator ==(Object other) => other is TooManyPendingRequests && other.max == max;

  @override
  int get hashCode => Object.hash(TooManyPendingRequests, max);

  @override
  String toString() => 'TooManyPendingRequests(max: $max)';
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

@immutable
final class CancellationTooLate extends DomainError {
  const CancellationTooLate({required this.notice});

  // Koliko pre početka čas najkasnije može da se otkaže.
  final Duration notice;

  @override
  bool operator ==(Object other) => other is CancellationTooLate && other.notice == notice;

  @override
  int get hashCode => Object.hash(CancellationTooLate, notice);

  @override
  String toString() => 'CancellationTooLate(notice: $notice)';
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
