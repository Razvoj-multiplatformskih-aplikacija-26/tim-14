import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'http.dart';
import 'sessions.dart';

/// The staff endpoints: a professor decides and records their lessons, an admin decides verifications.
/// In Spring terms: a `@RestController`, with the repositories and the clock injected through the constructor.
///
/// Every action follows the same five steps (§1.3 of the KT2 plan):
/// 1. take the caller from the request (`signedIn` put it there);
/// 2. load the record **fresh from the database**, never trusting the client's copy;
/// 3. missing, or not the caller's to see → 404;
/// 4. build the use case with the caller and run it, so the domain rules decide;
/// 5. answer with the record, or with the rule's refusal as a problem.
final class StaffHandlers {
  StaffHandlers(this._lessons, this._verifications, this._clock);

  final LessonRepository _lessons;
  final VerificationRepository _verifications;
  final Clock _clock;

  /// `POST /lessons/{id}/confirmation` → the confirmed lesson and the requests rejected with it.
  Future<Response> confirm(Request request) async {
    final caller = currentUser(request);
    final lesson = await _visibleLesson(request, caller);
    if (lesson == null) {
      return problem(const NotFound());
    }
    final result = await ConfirmLesson(_lessons, _clock, caller)(lesson);
    return respond(result, (confirmation) => confirmation.toDto().toJson());
  }

  /// `POST /lessons/{id}/rejection` → the rejected lesson.
  Future<Response> reject(Request request) async {
    final caller = currentUser(request);
    final lesson = await _visibleLesson(request, caller);
    if (lesson == null) {
      return problem(const NotFound());
    }
    final result = await RejectLesson(_lessons, _clock, caller)(lesson);
    return respond(result, (lesson) => lesson.toDto().toJson());
  }

  /// `POST /lessons/{id}/held` with `{"note": …}` (optional) → the lesson, now held.
  ///
  /// The body is read only after the visibility check, so a stranger gets 404 whatever they send.
  Future<Response> held(Request request) async {
    final caller = currentUser(request);
    final lesson = await _visibleLesson(request, caller);
    if (lesson == null) {
      return problem(const NotFound());
    }

    final text = HeldDto.fromJson(await readObject(request)).note;
    LessonNote? note;
    if (text != null) {
      final parsed = LessonNote.parse(text);
      if (parsed is Failure<LessonNote>) {
        return problem(parsed.error);
      }
      note = parsed.valueOrNull;
    }

    final result = await RecordHeld(_lessons, _clock, caller)(lesson, note: note);
    return respond(result, (lesson) => lesson.toDto().toJson());
  }

  /// `POST /lessons/{id}/no-show` → the lesson, now a no-show.
  Future<Response> noShow(Request request) async {
    final caller = currentUser(request);
    final lesson = await _visibleLesson(request, caller);
    if (lesson == null) {
      return problem(const NotFound());
    }
    final result = await RecordNoShow(_lessons, _clock, caller)(lesson);
    return respond(result, (lesson) => lesson.toDto().toJson());
  }

  /// `GET /verifications` → the profiles waiting for a decision, the longest-waiting first.
  ///
  /// A read with no record to load, and `GetVerificationQueue` takes no caller, so the rule is checked here:
  /// whoever may decide verifications may see what waits for a decision.
  Future<Response> verificationQueue(Request request) async {
    final caller = currentUser(request);
    if (!AccessPolicy.canDecideVerification(caller)) {
      return problem(const NotAllowed());
    }
    final queue = await GetVerificationQueue(_verifications)();
    return json(200, [for (final profile in queue) profile.toDto().toJson()]);
  }

  /// `POST /verifications/{id}/approval` → the profile, now verified.
  ///
  /// Profiles are public, so a missing one is 404 and a non-admin gets 403 from the use case: nothing is
  /// hidden by answering 403.
  Future<Response> approve(Request request) async {
    final caller = currentUser(request);
    final profile = await _verifications.find(_professorId(request));
    if (profile == null) {
      return problem(const NotFound());
    }
    final result = await VerifyProfessor(_verifications, _clock, caller)(profile);
    return respond(result, (verified) => verified.toDto().toJson());
  }

  /// `POST /verifications/{id}/rejection` with `{"reason": …}` → the profile, now rejected.
  /// `RejectProfessor` parses the reason itself, so a short one comes back as its `Failure`.
  Future<Response> rejectProfessor(Request request) async {
    final caller = currentUser(request);
    final profile = await _verifications.find(_professorId(request));
    if (profile == null) {
      return problem(const NotFound());
    }
    final reason = RejectionDto.fromJson(await readObject(request)).reason;
    final result = await RejectProfessor(_verifications, _clock, caller)(profile, reason: reason);
    return respond(result, (rejected) => rejected.toDto().toJson());
  }

  /// Steps 2 and 3 for a lesson: the lesson as the database has it now, or null if there is none or the caller
  /// may not see it. Both become 404, so a stranger cannot even tell that the lesson exists.
  Future<Lesson?> _visibleLesson(Request request, User caller) async {
    final lesson = await _lessons.find(LessonId(_pathId(request)));
    if (lesson == null || !AccessPolicy.canView(caller, lesson)) {
      return null;
    }
    return lesson;
  }

  UserId _professorId(Request request) => UserId(_pathId(request));

  /// The `:id` of the route. Every route of this class has one, so it is always there.
  String _pathId(Request request) => request.rawPathParameters[#id]!;
}
