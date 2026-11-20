import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

/// [VerificationRepository] over HTTP, for the admin in the backoffice.
final class HttpVerificationRepository implements VerificationRepository {
  const HttpVerificationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ProfessorProfile>> queue() async {
    final answer = await _api.get(ApiPaths.verifications);
    return accepted(
      answer,
      (json) => [for (final item in objects(json)) ProfessorProfileDto.fromJson(item).toDomain()],
    );
  }

  /// Through the public profile route: a signed-in admin gets it with the diploma, the LinkedIn and the reason.
  @override
  Future<ProfessorProfile?> find(UserId professor) async {
    final answer = await _api.get(ApiPaths.professor(professor.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return accepted(answer, (json) => ProfessorProfileDto.fromJson(object(json)).toDomain());
  }

  /// The decision follows from the new status. If another admin decided first, the server answers with
  /// `InvalidVerificationTransition`, which comes back as a `Failure`.
  @override
  Future<Result<ProfessorProfile>> save(ProfessorProfile profile, {required VerificationStatus from}) async {
    final id = profile.id.value;
    final answer = await switch (profile.verification) {
      Verified() => _api.post(ApiPaths.approval(id)),
      VerificationRejected(:final reason) => _api.post(
        ApiPaths.verificationRejection(id),
        body: RejectionDto(reason: reason.text).toJson(),
      ),
      final other => throw ArgumentError.value(other, 'profile.verification', 'The admin only approves or rejects'),
    };
    return resultOf(answer, (json) => ProfessorProfileDto.fromJson(object(json)).toDomain());
  }
}
