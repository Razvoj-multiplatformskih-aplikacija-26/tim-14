import 'json.dart';

/// An error on the wire: RFC 9457 problem details, sent as `application/problem+json`.
///
/// The server never sends text meant for the user. It sends a [code] plus the rule's numbers
/// ([value], [min], [max], [minutes]) and the client builds the message from them.
final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.code,
    required this.title,
    this.value,
    this.min,
    this.max,
    this.minutes,
    this.from,
    this.to,
  });

  static const mediaType = 'application/problem+json';

  static String typeOf(String code) => 'tag:raf.rs,2026:casovi/problem/$code';

  final int status;
  final String code;

  /// For developers reading logs and curl output, not for the user.
  final String title;
  final int? value;
  final int? min;
  final int? max;
  final int? minutes;

  /// A lesson status or a verification status as JSON. The mapping knows which, from [code].
  final Map<String, Object?>? from;
  final Map<String, Object?>? to;

  Map<String, Object?> toJson() => {
    'type': typeOf(code),
    'title': title,
    'status': status,
    'code': code,
    'value': ?value,
    'min': ?min,
    'max': ?max,
    'minutes': ?minutes,
    'from': ?from,
    'to': ?to,
  };

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    code: jsonString(json, 'code'),
    title: jsonOptionalString(json, 'title') ?? '',
    value: jsonOptionalInt(json, 'value'),
    min: jsonOptionalInt(json, 'min'),
    max: jsonOptionalInt(json, 'max'),
    minutes: jsonOptionalInt(json, 'minutes'),
    from: json['from'] == null ? null : jsonObject(json['from']),
    to: json['to'] == null ? null : jsonObject(json['to']),
  );
}
