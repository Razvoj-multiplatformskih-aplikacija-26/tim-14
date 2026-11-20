import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

/// [ProfessorRepository] over HTTP. Every route is public; a signed-in admin gets the verification details too.
final class HttpProfessorRepository implements ProfessorRepository {
  const HttpProfessorRepository(this._api);

  final ApiClient _api;

  @override
  Future<ProfessorsPage> professors({int offset = 0, int limit = 20}) async {
    final answer = await _api.get(ApiPaths.professors, query: {ApiQuery.offset: '$offset', ApiQuery.limit: '$limit'});
    return accepted(answer, (json) => ProfessorsPageDto.fromJson(object(json)).toDomain());
  }

  @override
  Future<ProfessorProfile> profile(UserId id) async {
    final answer = await _api.get(ApiPaths.professor(id.value));
    return accepted(answer, (json) => ProfessorProfileDto.fromJson(object(json)).toDomain());
  }

  @override
  Future<List<Listing>> listingsOf(UserId professor) async {
    final answer = await _api.get(ApiPaths.listingsOf(professor.value));
    return accepted(answer, (json) => [for (final item in objects(json)) ListingDto.fromJson(item).toDomain()]);
  }

  @override
  Future<List<Slot>> slotsOf(UserId professor) async {
    final answer = await _api.get(ApiPaths.slotsOf(professor.value));
    return accepted(answer, (json) => [for (final item in objects(json)) SlotDto.fromJson(item).toDomain()]);
  }

  /// Only the server looks a slot up by its id alone, when a request arrives. The clients read the slots of a
  /// professor, so there is no route for this and the client never calls it.
  @override
  Future<Slot?> findSlot(SlotId id) =>
      throw UnsupportedError('The clients read slots per professor; only the server finds a slot by id');
}
