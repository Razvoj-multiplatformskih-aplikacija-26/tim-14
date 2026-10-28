import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../catalog/city.dart';
import '../identifiers.dart';
import 'verification_status.dart';

typedef Education = ({String institution, String title, int fromYear, int? toYear});

typedef WorkExperience = ({String employer, String title, int fromYear, int? toYear});

@immutable
final class ProfessorProfile {
  const ProfessorProfile({
    required this.id,
    required this.fullName,
    required this.city,
    required this.bio,
    this.education = const [],
    this.experience = const [],
    this.verification = const NotVerified(),
  });

  final UserId id;
  final String fullName;
  final City city;
  final String bio;
  final List<Education> education;
  final List<WorkExperience> experience;
  final VerificationStatus verification;

  bool get isVerified => verification is Verified;

  ProfessorProfile copyWith({VerificationStatus? verification}) {
    return ProfessorProfile(
      id: id,
      fullName: fullName,
      city: city,
      bio: bio,
      education: education,
      experience: experience,
      verification: verification ?? this.verification,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProfessorProfile &&
      other.id == id &&
      other.fullName == fullName &&
      other.city == city &&
      other.bio == bio &&
      const ListEquality<Education>().equals(other.education, education) &&
      const ListEquality<WorkExperience>().equals(other.experience, experience) &&
      other.verification == verification;

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    city,
    bio,
    const ListEquality<Education>().hash(education),
    const ListEquality<WorkExperience>().hash(experience),
    verification,
  );

  @override
  String toString() => 'ProfessorProfile($id, $fullName, $verification)';
}
