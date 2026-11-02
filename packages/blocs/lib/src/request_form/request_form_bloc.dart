import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'request_form_event.dart';
import 'request_form_state.dart';

class RequestFormBloc extends Bloc<RequestFormEvent, RequestFormState> {
  RequestFormBloc(this._getProfessorPage, this._requestLesson, this._professorId, this._slotId)
    : super(const RequestFormLoading()) {
    on<RequestFormStarted>(_onStarted);
    on<MessageChanged>(_onMessageChanged);
    on<RequestSubmitted>(_onSubmitted);
  }

  final GetProfessorPage _getProfessorPage;
  final RequestLesson _requestLesson;
  final UserId _professorId;
  final SlotId _slotId;

  Future<void> _onStarted(RequestFormStarted event, Emitter<RequestFormState> emit) async {
    emit(const RequestFormLoading());
    try {
      final page = await _getProfessorPage(_professorId);

      // Termin tražimo među slobodnim, pa zauzet ili prošao termin ne može da se izabere.
      Slot? slot;
      for (final free in page.freeSlots) {
        if (free.id == _slotId) {
          slot = free;
        }
      }
      if (slot == null) {
        emit(const RequestFormSlotGone());
        return;
      }

      // Oglas sledi iz termina.
      final listingId = slot.listingId;
      final listing = page.listings.firstWhere((listing) => listing.id == listingId);
      emit(RequestFormReady(profile: page.profile, listing: listing, slot: slot));
    } on RepositoryException catch (e) {
      emit(RequestFormLoadFailure(e.message));
    }
  }

  void _onMessageChanged(MessageChanged event, Emitter<RequestFormState> emit) {
    final current = state;
    if (current is! RequestFormReady) {
      return;
    }

    // Prazna poruka nije greška dok se kuca, samo je dugme sivo.
    DomainError? error;
    if (event.text.trim().isNotEmpty) {
      final parsed = RequestMessage.parse(event.text);
      if (parsed is Failure<RequestMessage>) {
        error = parsed.error;
      }
    }

    emit(
      RequestFormReady(
        profile: current.profile,
        listing: current.listing,
        slot: current.slot,
        message: event.text,
        messageError: error,
      ),
    );
  }

  Future<void> _onSubmitted(RequestSubmitted event, Emitter<RequestFormState> emit) async {
    final current = state;
    if (current is! RequestFormReady || !current.canSend) {
      return;
    }

    emit(
      RequestFormReady(
        profile: current.profile,
        listing: current.listing,
        slot: current.slot,
        message: current.message,
        isSending: true,
      ),
    );

    try {
      final result = await _requestLesson(slot: current.slot, text: current.message);
      switch (result) {
        case Success(:final value):
          emit(RequestFormSent(value));
        case Failure(:final error):
          emit(
            RequestFormReady(
              profile: current.profile,
              listing: current.listing,
              slot: current.slot,
              message: current.message,
              submitError: error,
            ),
          );
      }
    } on RepositoryException catch (e) {
      emit(
        RequestFormReady(
          profile: current.profile,
          listing: current.listing,
          slot: current.slot,
          message: current.message,
          networkError: e.message,
        ),
      );
    }
  }
}
