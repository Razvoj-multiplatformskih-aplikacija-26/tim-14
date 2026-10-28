import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class LinkedInUrl {
  const LinkedInUrl._(this.value);

  static const _hosts = {'linkedin.com', 'www.linkedin.com'};

  final String value;

  static Result<LinkedInUrl> parse(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || uri.scheme != 'https' || !_hosts.contains(uri.host)) return const Failure(InvalidLinkedInUrl());
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != 'in') return const Failure(InvalidLinkedInUrl());
    return Success(LinkedInUrl._(uri.toString()));
  }

  @override
  bool operator ==(Object other) => other is LinkedInUrl && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'LinkedInUrl($value)';
}
