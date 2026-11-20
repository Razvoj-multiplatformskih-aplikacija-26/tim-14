import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import '../action_notice.dart';
import 'my_lessons_event.dart';
import 'my_lessons_state.dart';

class MyLessonsBloc extends Bloc<MyLessonsEvent, MyLessonsState> {
  MyLessonsBloc(this._getMyLessons, this._withdraw, this._cancel, this._clock, this._me)
    : super(const MyLessonsInitial()) {
    on<MyLessonsRequested>(_onRequested);
    on<MyLessonsRetried>(_onRetried);
    on<MyLessonsRefreshed>(_onRefreshed);
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

  // Sa listom na ekranu se osvežava tiho. Bez nje (prvo otvaranje, posle greške) učitava se sa spinerom.
  Future<void> _onRefreshed(MyLessonsRefreshed event, Emitter<MyLessonsState> emit) async {
    if (state is MyLessonsLoaded) {
      await _reload(emit);
    } else {
      await _load(emit);
    }
  }

  Future<void> _onWithdrawn(LessonWithdrawn event, Emitter<MyLessonsState> emit) async {
    await _act(() => _withdraw(event.lesson), emit);
  }

  Future<void> _onCancelled(LessonCancelled event, Emitter<MyLessonsState> emit) async {
    await _act(() => _cancel(event.lesson), emit);
  }

  // Isto za povlačenje i otkazivanje.
  // - Uspeh: tiho ponovno učitavanje, da se vidi stanje kakvo je na serveru.
  // - Pravilo nije prošlo (u aplikaciji ili na serveru, npr. profesor je u međuvremenu potvrdio čas): prvo poruka,
  //   pa tiho ponovno učitavanje, jer je lista na ekranu možda zastarela. Tako se ponaša klijent koji je zakasnio.
  // - Server nije odgovorio: lista ostaje, a poruka kaže zašto. Ceo ekran ne prelazi u grešku.
  Future<void> _act(Future<Result<Lesson>> Function() action, Emitter<MyLessonsState> emit) async {
    try {
      final result = await action();
      if (result case Failure(:final error)) {
        _notify(emit, ActionRejected(error));
      }
      await _reload(emit);
    } on RepositoryException catch (e) {
      _notify(emit, ActionFailed(e.failure));
    }
  }

  Future<void> _load(Emitter<MyLessonsState> emit) async {
    emit(const MyLessonsLoading());
    try {
      _show(await _getMyLessons(), emit);
    } on RepositoryException catch (e) {
      emit(MyLessonsFailure(e.failure));
    }
  }

  // Bez spinera: lista ostaje na ekranu dok stižu novi podaci. Novo stanje nema poruku, pa se SnackBar koji je
  // već na ekranu ne pokaže ponovo.
  Future<void> _reload(Emitter<MyLessonsState> emit) async {
    try {
      _show(await _getMyLessons(), emit);
    } on RepositoryException catch (e) {
      _notify(emit, ActionFailed(e.failure));
    }
  }

  void _show(List<Lesson> lessons, Emitter<MyLessonsState> emit) {
    if (lessons.isEmpty) {
      emit(const MyLessonsEmpty());
    } else {
      emit(MyLessonsLoaded(_toItems(lessons)));
    }
  }

  // Poruka uz listu koja je već na ekranu. Prvo stanje bez poruke, pa sa njom: tako ista poruka dva puta zaredom
  // ipak stigne do ekrana, jer su dva jednaka stanja za Bloc jedno isto stanje.
  void _notify(Emitter<MyLessonsState> emit, ActionNotice notice) {
    final current = state;
    if (current is! MyLessonsLoaded) {
      if (notice case ActionFailed(:final failure)) {
        emit(MyLessonsFailure(failure));
      }
      return;
    }
    emit(MyLessonsLoaded(current.items));
    emit(MyLessonsLoaded(current.items, notice: notice));
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
