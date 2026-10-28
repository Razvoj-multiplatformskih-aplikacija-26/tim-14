import 'package:meta/meta.dart';

import '../catalog/city.dart';
import '../catalog/level.dart';
import '../catalog/subject.dart';
import '../identifiers.dart';
import 'lesson_duration.dart';
import 'price.dart';

@immutable
final class Listing {
  const Listing({
    required this.id,
    required this.professorId,
    required this.subject,
    required this.level,
    required this.city,
    required this.description,
    required this.price,
    required this.duration,
  });

  final ListingId id;
  final UserId professorId;
  final Subject subject;
  final Level level;
  final City city;
  final String description;
  final Price price;
  final LessonDuration duration;

  @override
  bool operator ==(Object other) =>
      other is Listing &&
      other.id == id &&
      other.professorId == professorId &&
      other.subject == subject &&
      other.level == level &&
      other.city == city &&
      other.description == description &&
      other.price == price &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(id, professorId, subject, level, city, description, price, duration);

  @override
  String toString() => 'Listing($id, ${subject.name}, ${level.name}, ${city.name}, $price, ${duration.minutes} min)';
}
