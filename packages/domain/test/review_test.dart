import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final held = lessonAt(lessonStart, status: Held(at: lessonStart.add(const Duration(hours: 1))));
  final rating = Rating.parse(5).valueOrNull!;
  final text = ReviewText.parse('Odlično objašnjava.').valueOrNull!;
  final later = lessonStart.add(const Duration(days: 1));

  Result<Review> write(Lesson lesson, {User by = student, Review? existing}) => writeReview(
    lesson,
    id: const ReviewId('r-1'),
    by: by,
    rating: rating,
    text: text,
    existingReview: existing,
    now: later,
  );

  test('student reviews a held lesson', () {
    final review = write(held).valueOrNull!;
    expect(review.lessonId, held.id);
    expect(review.professorId, professor.id);
    expect(review.studentId, student.id);
    expect(review.rating, rating);
    expect(review.text, text);
    expect(review.createdAt, later);
  });

  test('only a held lesson can be reviewed', () {
    final statuses = <LessonStatus>[
      const Pending(),
      Confirmed(at: now),
      Cancelled(by: student.id, at: now),
      NoShow(at: lessonStart),
    ];
    for (final status in statuses) {
      expect(write(held.copyWith(status: status)).errorOrNull, isA<LessonNotHeld>());
    }
  });

  test('one review per lesson', () {
    expect(write(held, existing: write(held).valueOrNull).errorOrNull, isA<AlreadyReviewed>());
  });

  test("only the lesson's student can review it", () {
    for (final user in [otherStudent, professor, admin]) {
      expect(write(held, by: user).errorOrNull, isA<NotAllowed>());
    }
  });
}
