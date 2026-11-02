import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

sealed class RequestFormState extends Equatable {
  const RequestFormState();

  @override
  List<Object?> get props => [];
}

class RequestFormLoading extends RequestFormState {
  const RequestFormLoading();
}

class RequestFormLoadFailure extends RequestFormState {
  const RequestFormLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// Termin je u međuvremenu zauzet ili je prošao, pa forma nema šta da pošalje.
class RequestFormSlotGone extends RequestFormState {
  const RequestFormSlotGone();
}

class RequestFormReady extends RequestFormState {
  const RequestFormReady({
    required this.profile,
    required this.listing,
    required this.slot,
    this.message = '',
    this.messageLength = 0,
    this.messageError,
    this.isSending = false,
    this.submitError,
    this.networkError,
  });

  final ProfessorProfile profile;
  final Listing listing;
  final Slot slot;
  final String message;

  // Broj znakova za brojač ispod polja, broji ga domen.
  final int messageLength;

  // Greška u poruci dok se kuca, npr. preko 300 znakova.
  final DomainError? messageError;
  final bool isSending;

  // Pravilo iz domena koje nije prošlo pri slanju, npr. već 3 zahteva na čekanju.
  final DomainError? submitError;

  // Slanje nije stiglo do repozitorijuma.
  final String? networkError;

  bool get canSend => message.trim().isNotEmpty && messageError == null && !isSending;

  @override
  List<Object?> get props => [
    profile,
    listing,
    slot,
    message,
    messageLength,
    messageError,
    isSending,
    submitError,
    networkError,
  ];
}

class RequestFormSent extends RequestFormState {
  const RequestFormSent(this.lesson);

  final Lesson lesson;

  @override
  List<Object?> get props => [lesson];
}
