import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'demo_data.dart';
import 'fail_switch.dart';

// Prijava bez servera, za testove ekrana i za demo sa --dart-define=FAKE_DATA=true.
// Nalozi i lozinka su isti kao u seed podacima na serveru, pa se demo radi istim rečima.
final class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository(this._failSwitch, {this.signedIn, this.delay = const Duration(milliseconds: 400)});

  static const password = 'casovi-demo';
  static const accounts = <String, User>{'profesor1': milica, 'admin1': admin, 'ucenik1': ana};

  final FailSwitch _failSwitch;
  final Duration delay;
  final _expirations = StreamController<void>.broadcast();

  // Ko je prijavljen. Test ga postavi unapred kad hoće da aplikacija krene već prijavljena.
  User? signedIn;

  // Kao kad server odbije istekao token: SessionBloc čuje događaj i vraća na prijavu.
  void expire() {
    signedIn = null;
    _expirations.add(null);
  }

  @override
  Future<User?> logIn({required String login, required String password}) async {
    await Future<void>.delayed(delay);
    _failSwitch.check();
    final user = accounts[login];
    if (user == null || password != FakeSessionRepository.password) return null;
    return signedIn = user;
  }

  @override
  Future<User?> current() async {
    _failSwitch.check();
    return signedIn;
  }

  @override
  Future<void> logOut() async {
    signedIn = null;
    _failSwitch.check();
  }

  @override
  Stream<void> get expirations => _expirations.stream;
}
