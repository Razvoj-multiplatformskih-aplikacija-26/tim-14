import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'linkedin_url.dart';

sealed class VerificationStatus {
  const VerificationStatus();

  bool canTransitionTo(VerificationStatus next) => switch ((this, next)) {
    (NotVerified() || VerificationRejected(), AwaitingReview()) => true,
    (AwaitingReview(), Verified() || VerificationRejected()) => true,
    _ => false,
  };
}

final class NotVerified extends VerificationStatus {
  const NotVerified();

  @override
  String toString() => 'NotVerified';
}

@immutable
final class AwaitingReview extends VerificationStatus {
  const AwaitingReview({required this.submittedAt, required this.diplomaFile, required this.linkedIn});

  final DateTime submittedAt;
  final String diplomaFile;
  final LinkedInUrl linkedIn;

  @override
  bool operator ==(Object other) =>
      other is AwaitingReview &&
      other.submittedAt == submittedAt &&
      other.diplomaFile == diplomaFile &&
      other.linkedIn == linkedIn;

  @override
  int get hashCode => Object.hash(submittedAt, diplomaFile, linkedIn);

  @override
  String toString() => 'AwaitingReview(since $submittedAt)';
}

@immutable
final class Verified extends VerificationStatus {
  const Verified({required this.by, required this.at});

  final UserId by;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Verified && other.by == by && other.at == at;

  @override
  int get hashCode => Object.hash(Verified, by, at);

  @override
  String toString() => 'Verified(by $by at $at)';
}

@immutable
final class VerificationRejected extends VerificationStatus {
  const VerificationRejected({required this.by, required this.at, required this.reason});

  final UserId by;
  final DateTime at;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is VerificationRejected && other.by == by && other.at == at && other.reason == reason;

  @override
  int get hashCode => Object.hash(by, at, reason);

  @override
  String toString() => 'VerificationRejected("$reason" by $by at $at)';
}
