import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'demo_data.dart';

// Prijava bez servera, za testove ekrana i rad sa demo podacima. Nalozi i lozinka su isti kao na serveru.
final class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository({User? signedIn}) : _current = signedIn;

  static const password = 'casovi-demo';

  static const accounts = <String, User>{
    'ucenik1': ana,
    'ucenik2': User(id: UserId('nikola-petrovic'), name: 'Nikola Petrović', role: Role.student),
    'profesor1': User(id: UserId('milica-jovanovic'), name: 'Milica Jovanović', role: Role.professor),
    'admin1': User(id: UserId('jovana-ilic'), name: 'Jovana Ilić', role: Role.admin),
  };

  User? _current;
  final _expirations = StreamController<void>.broadcast();

  @override
  Future<User?> logIn({required String login, required String password}) async {
    final user = password == FakeSessionRepository.password ? accounts[login] : null;
    _current = user;
    return user;
  }

  @override
  Future<User?> current() async => _current;

  @override
  Future<void> logOut() async => _current = null;

  @override
  Stream<void> get expirations => _expirations.stream;

  // Kao kad server odbije istekao token.
  void expire() {
    _current = null;
    _expirations.add(null);
  }
}
