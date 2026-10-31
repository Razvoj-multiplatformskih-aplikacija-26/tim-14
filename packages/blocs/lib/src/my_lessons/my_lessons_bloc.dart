import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'my_lessons_event.dart';
import 'my_lessons_state.dart';

class MyLessonsBloc extends Bloc<MyLessonsEvent, MyLessonsState> {
  MyLessonsBloc(this._getMyLessons, this._withdraw, this._cancel, this._clock, this._me)
    : super(const MyLessonsInitial()) {
    on<MyLessonsRequested>(_onRequested);
    on<MyLessonsRetried>(_onRetried);
    on<LessonWithdrawn>(_onWithdrawn);
    on<LessonCancelled>(_onCancelled);
  }

  final GetMyLessons _getMyLessons;
  final WithdrawRequest _withdraw;
  final CancelLesson _cancel;
  final Clock _clock;
  final User _me;

  Future<void> _onRequested(MyLessonsRequested event, Emitter<MyLessonsState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(MyLessonsRetried event, Emitter<MyLessonsState> emit) async {
    await _load(emit);
  }

  Future<void> _onWithdrawn(LessonWithdrawn event, Emitter<MyLessonsState> emit) async {
    try {
      final result = await _withdraw(event.lesson);
      await _showResult(result, emit);
    } on RepositoryException catch (e) {
      emit(MyLessonsFailure(e.message));
    }
  }

  Future<void> _onCancelled(LessonCancelled event, Emitter<MyLessonsState> emit) async {
    try {
      final result = await _cancel(event.lesson);
      await _showResult(result, emit);
    } on RepositoryException catch (e) {
      emit(MyLessonsFailure(e.message));
    }
  }

  Future<void> _load(Emitter<MyLessonsState> emit) async {
    emit(const MyLessonsLoading());
    try {
      final lessons = await _getMyLessons();
      if (lessons.isEmpty) {
        emit(const MyLessonsEmpty());
      } else {
        emit(MyLessonsLoaded(_toItems(lessons)));
      }
    } on RepositoryException catch (e) {
      emit(MyLessonsFailure(e.message));
    }
  }

  // Ako akcija nije uspela, lista ostaje ista i dodaje se greška.
  // Ako je uspela, ponovo učitamo časove da se vidi novo stanje.
  Future<void> _showResult(Result<Lesson> result, Emitter<MyLessonsState> emit) async {
    final current = state;
    if (result is Failure<Lesson> && current is MyLessonsLoaded) {
      emit(MyLessonsLoaded(current.items, actionError: result.error));
      return;
    }

    final lessons = await _getMyLessons();
    emit(MyLessonsLoaded(_toItems(lessons)));
  }

  // Za svaki čas unapred proverimo da li akcija može, pa ekran ne mora da zna pravila.
  List<LessonItem> _toItems(List<Lesson> lessons) {
    final now = _clock.now();
    final items = <LessonItem>[];

    for (final lesson in lessons) {
      if (lesson.status is Pending) {
        final check = withdrawRequest(lesson, by: _me, now: now);
        items.add(LessonItem(lesson: lesson, action: LessonAction.withdraw, blockedBy: check.errorOrNull));
      } else if (lesson.status is Confirmed) {
        final check = cancelLesson(lesson, by: _me, now: now);
        items.add(LessonItem(lesson: lesson, action: LessonAction.cancel, blockedBy: check.errorOrNull));
      } else {
        items.add(LessonItem(lesson: lesson, action: LessonAction.none));
      }
    }

    return items;
  }
}
