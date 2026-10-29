import '../access_policy.dart';
import '../errors.dart';
import '../identifiers.dart';
import '../lesson/lesson.dart';
import '../lesson/lesson_status.dart';
import '../result.dart';
import '../user.dart';
import 'rating.dart';
import 'review.dart';
import 'review_text.dart';

Result<Review> writeReview(
  Lesson lesson, {
  required ReviewId id,
  required User by,
  required Rating rating,
  ReviewText? text,
  required Review? existingReview,
  required DateTime now,
}) {
  if (!AccessPolicy.canWriteReview(by, lesson)) return const Failure(NotAllowed());
  if (lesson.status is! Held) return const Failure(LessonNotHeld());
  if (existingReview != null) return const Failure(AlreadyReviewed());
  return Success(
    Review(
      id: id,
      lessonId: lesson.id,
      professorId: lesson.professorId,
      studentId: lesson.studentId,
      rating: rating,
      text: text,
      createdAt: now,
    ),
  );
}
