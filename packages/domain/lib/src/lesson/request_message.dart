import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class RequestMessage {
  const RequestMessage._(this.text);

  static const maxLength = 300;

  final String text;

  static Result<RequestMessage> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length == 0 || length > maxLength) return Failure(InvalidRequestMessage(length));
    return Success(RequestMessage._(text));
  }

  @override
  bool operator ==(Object other) => other is RequestMessage && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'RequestMessage("$text")';
}
