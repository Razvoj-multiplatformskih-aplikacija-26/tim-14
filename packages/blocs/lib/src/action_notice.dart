import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

// Ishod poslednje akcije koji ekran pokaže kao SnackBar. Zapečaćena klasa umesto dva nullable polja,
// jer bi ta dva polja mogla da budu postavljena u isto vreme, a ovde je uvek tačno jedan slučaj.
sealed class ActionNotice extends Equatable {
  const ActionNotice();
}

// Pravilo nije prošlo, u aplikaciji ili na serveru (npr. SlotTaken kad je drugi profesor bio brži).
class ActionRejected extends ActionNotice {
  const ActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

// Akcija nije stigla do odgovora (nema veze, greška servera…). Lista ostaje na ekranu.
class ActionFailed extends ActionNotice {
  const ActionFailed(this.failure);

  final RepositoryFailure failure;

  @override
  List<Object?> get props => [failure];
}
