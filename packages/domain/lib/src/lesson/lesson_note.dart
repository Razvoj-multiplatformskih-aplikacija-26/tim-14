import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class LessonNote {
  const LessonNote._(this.text);

  static const maxLength = 500;

  final String text;

  bool get isEmpty => text.isEmpty;

  static Result<LessonNote> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length > maxLength) return Failure(NoteTooLong(length));
    return Success(LessonNote._(text));
  }

  @override
  bool operator ==(Object other) => other is LessonNote && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'LessonNote("$text")';
}
