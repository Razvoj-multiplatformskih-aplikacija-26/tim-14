import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'rating.dart';
import 'review_text.dart';

@immutable
final class Review {
  Review({
    required this.id,
    required this.lessonId,
    required this.professorId,
    required this.studentId,
    required this.rating,
    required DateTime createdAt,
    this.text,
  }) : createdAt = createdAt.toUtc();

  final ReviewId id;
  final LessonId lessonId;
  final UserId professorId;
  final UserId studentId;
  final Rating rating;
  final ReviewText? text;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Review &&
      other.id == id &&
      other.lessonId == lessonId &&
      other.professorId == professorId &&
      other.studentId == studentId &&
      other.rating == rating &&
      other.text == text &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, lessonId, professorId, studentId, rating, text, createdAt);

  @override
  String toString() => 'Review($id, $lessonId, $rating)';
}
