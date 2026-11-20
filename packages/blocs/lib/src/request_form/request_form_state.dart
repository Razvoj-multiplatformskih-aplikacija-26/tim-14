import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

sealed class RequestFormState extends Equatable {
  const RequestFormState();

  @override
  List<Object?> get props => [];
}

class RequestFormLoading extends RequestFormState {
  const RequestFormLoading();
}

// Forma nije učitana. Nosi samo vrstu greške, a tekst za ekran pravi aplikacija.
class RequestFormLoadFailure extends RequestFormState {
  const RequestFormLoadFailure(this.failure);

  final RepositoryFailure failure;

  @override
  List<Object?> get props => [failure];
}

// Termin je u međuvremenu zauzet ili je prošao, pa forma nema šta da pošalje. Isto stanje dolazi i kad
// server pri slanju javi da je termin zauzet: drugi učenik je bio brži, i profesor je njegov zahtev već potvrdio.
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

  // Slanje nije stiglo do servera (ili je prijava istekla). Poruka ostaje u polju, pa može da se pošalje ponovo.
  final RepositoryFailure? networkError;

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
