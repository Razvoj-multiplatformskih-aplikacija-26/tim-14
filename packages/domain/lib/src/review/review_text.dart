import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class ReviewText {
  const ReviewText._(this.text);

  static const maxLength = 1000;

  final String text;

  bool get isEmpty => text.isEmpty;

  static Result<ReviewText> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length > maxLength) return Failure(ReviewTextTooLong(length));
    return Success(ReviewText._(text));
  }

  @override
  bool operator ==(Object other) => other is ReviewText && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'ReviewText("$text")';
}
