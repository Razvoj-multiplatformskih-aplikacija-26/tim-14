import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'lessons/lesson_queue_page.dart';
import 'login/login_page.dart';
import 'shell/app_shell.dart';
import 'shell/signed_in_scope.dart';
import 'verification/verification_page.dart';

abstract final class Routes {
  static const splash = '/';
  static const login = '/prijava';
  static const lessons = '/casovi';
  static const verification = '/verifikacija';
}

// Svaka uloga ima tačno jedan deo aplikacije.
String homeFor(Role role) => switch (role) {
  Role.professor => Routes.lessons,
  Role.admin => Routes.verification,
  Role.student => throw ArgumentError('Učenik ne koristi backoffice'),
};

// Za svako stanje sesije postoji tačno jedno mesto. Ruter ne pamti odakle je ko došao.
String _placeFor(SessionState session) => switch (session) {
  SessionUnknown() => Routes.splash,
  SignedOut() => Routes.login,
  final SignedIn signedIn => homeFor(signedIn.user.role),
};

GoRouter createRouter(SessionBloc session) {
  return GoRouter(
    initialLocation: Routes.splash,
    // Prijava, odjava i istek menjaju stanje SessionBloc-a. Ruter tada ponovo pita redirect.
    refreshListenable: _SessionChanges(session.stream),
    // Jedno pravilo pokriva sve: splash dok se ne zna, prijavu kad niko nije prijavljen, i deo uloge
    // za prijavljenog, pa i kad na webu ukuca tuđu adresu ili adresu koja ne postoji.
    redirect: (context, state) {
      final place = _placeFor(session.state);
      return state.matchedLocation == place ? null : place;
    },
    // Bez animacije prelaza: prijava i splash nisu strane na koje se ide napred i nazad.
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const _Splash()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const LoginPage()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) =>
            NoTransitionPage(key: state.pageKey, child: _signedIn(session.state, state, child)),
        routes: [
          GoRoute(path: Routes.lessons, builder: (context, state) => const LessonQueuePage()),
          GoRoute(path: Routes.verification, builder: (context, state) => const VerificationPage()),
        ],
      ),
    ],
  );
}

// Redirect ovde pušta samo prijavljenog. U trenutku između odjave i preusmeravanja crta prazno.
// Ključ je id korisnika: drugi korisnik dobija novi SignedInScope, pa i nove Blocove.
Widget _signedIn(SessionState session, GoRouterState state, Widget child) {
  if (session is! SignedIn) return const SizedBox.shrink();
  final user = session.user;
  return SignedInScope(
    key: ValueKey(user.id),
    user: user,
    child: AppShell(user: user, location: state.matchedLocation, child: child),
  );
}

// GoRouter sluša Listenable, a Bloc daje Stream. Ova klasa ih spaja: svako novo stanje sesije javi ruteru.
class _SessionChanges extends ChangeNotifier {
  _SessionChanges(Stream<SessionState> changes) {
    _subscription = changes.listen((_) => notifyListeners());
  }

  late final StreamSubscription<SessionState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Dok se proverava sesija od ranije. Ako server ne odgovara, ApiClient odustaje posle 10 s.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
