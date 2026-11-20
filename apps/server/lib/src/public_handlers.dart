import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'http.dart';
import 'sessions.dart';

/// The professor pages, open to everyone without signing in: the list and one professor's profile, listings,
/// slots and taken slots. They sit behind `optionallySignedIn`, so a signed-in admin sees more than a visitor.
final class PublicHandlers {
  PublicHandlers(this._professors, this._lessons);

  final ProfessorRepository _professors;
  final LessonRepository _lessons;

  static const defaultLimit = 20;
  static const maxLimit = 50;

  /// `GET /professors?offset=&limit=` → one page. The professor list is the one list that grows without bound,
  /// so it comes in pages: [defaultLimit] by default, never more than [maxLimit].
  Future<Response> professors(Request request) async {
    final query = request.url.queryParameters;
    final offset = _whole(query[ApiQuery.offset], name: ApiQuery.offset, fallback: 0, min: 0);
    final limit = _whole(query[ApiQuery.limit], name: ApiQuery.limit, fallback: defaultLimit, min: 1);
    final page = await GetProfessors(_professors)(offset: offset, limit: limit > maxLimit ? maxLimit : limit);

    final viewer = optionalUser(request);
    final visible = ProfessorsPage(
      items: [
        for (final item in page.items)
          ProfessorSummary(profile: visibleTo(item.profile, viewer), listings: item.listings),
      ],
      nextOffset: page.nextOffset,
    );
    return json(200, visible.toDto().toJson());
  }

  /// `GET /professors/{id}` → the profile as the caller may see it. An unknown professor is 404.
  Future<Response> profile(Request request) async {
    final profile = await _professors.profile(_professorId(request));
    return json(200, visibleTo(profile, optionalUser(request)).toDto().toJson());
  }

  /// `GET /professors/{id}/listings`
  Future<Response> listings(Request request) async {
    final listings = await _professors.listingsOf(_professorId(request));
    return json(200, [for (final listing in listings) listing.toDto().toJson()]);
  }

  /// `GET /professors/{id}/slots`: every slot of the professor. Which are still free, the client works out with
  /// `freeSlots` from the domain and the taken slots below.
  Future<Response> slots(Request request) async {
    final slots = await _professors.slotsOf(_professorId(request));
    return json(200, [for (final slot in slots) slot.toDto().toJson()]);
  }

  /// `GET /professors/{id}/taken-slots`: only which slots already have a confirmed lesson. Other students'
  /// requests and messages never leave the server.
  Future<Response> takenSlots(Request request) async {
    final taken = await _lessons.takenSlotsOf(_professorId(request));
    return json(200, taken.toDto().toJson());
  }

  UserId _professorId(Request request) => UserId(request.rawPathParameters[#id]!);
}

/// A whole number from the query, or [fallback] when it is absent. Anything else is the client's mistake: a
/// [FormatException], which `handleErrors` answers with 400.
int _whole(String? value, {required String name, required int fallback, required int min}) {
  if (value == null) {
    return fallback;
  }
  final number = int.tryParse(value);
  if (number == null || number < min) {
    throw FormatException('Expected "$name" to be a whole number of at least $min', value);
  }
  return number;
}
