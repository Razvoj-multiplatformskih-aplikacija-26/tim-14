import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class Price {
  const Price._(this.dinars);

  final int dinars;

  static Result<Price> parse(int dinars) {
    if (dinars <= 0) return Failure(InvalidPrice(dinars));
    return Success(Price._(dinars));
  }

  @override
  bool operator ==(Object other) => other is Price && other.dinars == dinars;

  @override
  int get hashCode => dinars.hashCode;

  @override
  String toString() => 'Price($dinars RSD)';
}
