import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

/// [LessonRepository] over HTTP, for both apps. The Blocs and the screens use the same port as with the fakes.
///
/// The server never trusts the client's copy of a lesson: a write sends only what the action needs (the slot and
/// the message, a note, nothing at all), and the server loads the lesson itself and runs the same use case.
final class HttpLessonRepository implements LessonRepository {
  const HttpLessonRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Lesson>> lessonsOf(UserId student) => _lessons({ApiQuery.student: student.value});

  @override
  Future<List<Lesson>> lessonsOfProfessor(UserId professor) => _lessons({ApiQuery.professor: professor.value});

  @override
  Future<List<Lesson>> lessonsForSlot(SlotId slot) => _lessons({ApiQuery.slot: slot.value});

  @override
  Future<Set<SlotId>> takenSlotsOf(UserId professor) async {
    final answer = await _api.get(ApiPaths.takenSlotsOf(professor.value));
    return accepted(answer, (json) => TakenSlotsDto.fromJson(object(json)).toDomain());
  }

  /// Null when there is no such lesson, or it is someone else's: the server answers both with 404.
  @override
  Future<Lesson?> find(LessonId id) async {
    final answer = await _api.get(ApiPaths.lesson(id.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return accepted(answer, _lesson);
  }

  /// A stand-in id. The real one is given by whoever stores the lesson, which is the server.
  @override
  Future<LessonId> nextId() async => const LessonId('nov');

  /// Sends only the slot and the message. The answer is the lesson as the server stored it, with its real id.
  @override
  Future<Result<Lesson>> create(Lesson lesson) async {
    final body = NewLessonDto(slotId: lesson.slotId.value, message: lesson.message.text);
    return resultOf(await _api.post(ApiPaths.lessons, body: body.toJson()), _lesson);
  }

  /// The action follows from where the lesson comes from and where it goes. On the server, [from] becomes the
  /// conditional write `WHERE status = from`, so a lesson someone changed meanwhile comes back as a `Failure`.
  @override
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from}) async {
    final id = lesson.id.value;
    final answer = await switch ((from, lesson.status)) {
      (Pending(), Cancelled()) => _api.post(ApiPaths.withdrawal(id)),
      (Confirmed(), Cancelled()) => _api.post(ApiPaths.cancellation(id)),
      (_, Rejected()) => _api.post(ApiPaths.rejection(id)),
      (_, Held(:final note)) => _api.post(ApiPaths.held(id), body: HeldDto(note: note?.text).toJson()),
      (_, NoShow()) => _api.post(ApiPaths.noShow(id)),
      _ => throw ArgumentError.value(lesson.status, 'lesson.status', 'No action moves a lesson from $from to it'),
    };
    return resultOf(answer, _lesson);
  }

  /// One call: the server confirms and rejects the other requests for the slot in one transaction.
  @override
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation) async {
    final answer = await _api.post(ApiPaths.confirmation(confirmation.confirmed.id.value));
    return resultOf(answer, (json) => ConfirmationDto.fromJson(object(json)).toDomain());
  }

  Future<List<Lesson>> _lessons(Map<String, String> query) async {
    final answer = await _api.get(ApiPaths.lessons, query: query);
    return accepted(answer, (json) => [for (final item in objects(json)) _lesson(item)]);
  }

  Lesson _lesson(Object? json) => LessonDto.fromJson(object(json)).toDomain();
}
