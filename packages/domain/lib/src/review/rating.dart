import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class Rating {
  const Rating._(this.stars);

  static const min = 1;
  static const max = 5;

  final int stars;

  static Result<Rating> parse(int stars) {
    if (stars < min || stars > max) return Failure(InvalidRating(stars));
    return Success(Rating._(stars));
  }

  @override
  bool operator ==(Object other) => other is Rating && other.stars == stars;

  @override
  int get hashCode => stars.hashCode;

  @override
  String toString() => 'Rating($stars)';
}
