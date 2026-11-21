import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'http.dart';
import 'lesson_notifications.dart';
import 'sessions.dart';

/// The lesson endpoints of the student: reading lessons, a new request, withdrawing it and cancelling a confirmed
/// lesson. The two reads serve the backoffice too: a professor reads their lessons the same way.
///
/// Every action follows the same five steps (§3.3 of the KT2 plan):
/// 1. take the caller from the request (`signedIn` put it there);
/// 2. load the record **fresh from the database**, never trusting the client's copy;
/// 3. missing, or not the caller's to see → 404;
/// 4. build the use case with the caller and run it, so the domain rules decide;
/// 5. answer with the record, or with the rule's refusal as a problem.
///
/// After a new request the handler also starts the professor's email, without waiting for it.
final class StudentHandlers {
  StudentHandlers(this._lessons, this._professors, this._clock, this._notifications);

  final LessonRepository _lessons;
  final ProfessorRepository _professors;
  final Clock _clock;
  final LessonNotifications _notifications;

  /// `GET /lessons?student=` · `?professor=` · `?slot=`, exactly one of them.
  ///
  /// The id in the query is only a filter. Who calls the server knows from the token, and only the lessons the
  /// caller may see go out: a student who asks for a professor's lessons gets their own lessons with that
  /// professor, never another student's requests and messages.
  Future<Response> lessons(Request request) async {
    final caller = currentUser(request);
    final query = request.url.queryParameters;
    final filters = [ApiQuery.student, ApiQuery.professor, ApiQuery.slot].where(query.containsKey).toList();
    if (filters.length != 1) {
      return badRequest('Give exactly one of student, professor and slot');
    }
    final id = query[filters.single]!;
    final lessons = switch (filters.single) {
      ApiQuery.student => await _lessons.lessonsOf(UserId(id)),
      ApiQuery.professor => await _lessons.lessonsOfProfessor(UserId(id)),
      _ => await _lessons.lessonsForSlot(SlotId(id)),
    };
    return json(200, [
      for (final lesson in lessons)
        if (AccessPolicy.canView(caller, lesson)) lesson.toDto().toJson(),
    ]);
  }

  /// `GET /lessons/{id}` → the lesson, or 404 if there is none or it is someone else's.
  Future<Response> lesson(Request request) async {
    final lesson = await _visibleLesson(request, currentUser(request));
    if (lesson == null) {
      return problem(const NotFound());
    }
    return json(200, lesson.toDto().toJson());
  }

  /// `POST /lessons` with `{slotId, message}` → 201 and the new request.
  ///
  /// The client sends only the slot and the message. The time, the professor and both names come from the
  /// database, through the slot and the use case, so the client cannot change them.
  Future<Response> request(Request request) async {
    final caller = currentUser(request);
    final body = NewLessonDto.fromJson(await readObject(request));
    final slot = await _professors.findSlot(SlotId(body.slotId));
    if (slot == null) {
      return problem(const NotFound());
    }
    final result = await RequestLesson(_lessons, _professors, _clock, caller)(slot: slot, text: body.message);
    if (result is Success<Lesson>) {
      unawaited(_notifications.requested(result.value));
    }
    return respond(result, (lesson) => lesson.toDto().toJson(), status: 201);
  }

  /// `POST /lessons/{id}/withdrawal` → the request, now withdrawn. Only the student of a pending request.
  Future<Response> withdraw(Request request) async {
    final caller = currentUser(request);
    final lesson = await _visibleLesson(request, caller);
    if (lesson == null) {
      return problem(const NotFound());
    }
    final result = await WithdrawRequest(_lessons, _clock, caller)(lesson);
    return respond(result, (withdrawn) => withdrawn.toDto().toJson());
  }

  /// `POST /lessons/{id}/cancellation` → the lesson, now cancelled. The student or the professor of a confirmed
  /// lesson, at the latest the notice before it starts.
  Future<Response> cancel(Request request) async {
    final caller = currentUser(request);
    final lesson = await _visibleLesson(request, caller);
    if (lesson == null) {
      return problem(const NotFound());
    }
    final result = await CancelLesson(_lessons, _clock, caller)(lesson);
    return respond(result, (cancelled) => cancelled.toDto().toJson());
  }

  /// Steps 2 and 3: the lesson as the database has it now, or null if there is none or the caller may not see it.
  /// Both become 404, so a stranger cannot even tell that the lesson exists.
  Future<Lesson?> _visibleLesson(Request request, User caller) async {
    final lesson = await _lessons.find(LessonId(request.rawPathParameters[#id]!));
    if (lesson == null || !AccessPolicy.canView(caller, lesson)) {
      return null;
    }
    return lesson;
  }
}
