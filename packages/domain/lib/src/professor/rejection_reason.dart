import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class RejectionReason {
  const RejectionReason._(this.text);

  static const minLength = 10;

  final String text;

  static Result<RejectionReason> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length < minLength) return Failure(RejectionReasonTooShort(length));
    return Success(RejectionReason._(text));
  }

  @override
  bool operator ==(Object other) => other is RejectionReason && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'RejectionReason("$text")';
}
