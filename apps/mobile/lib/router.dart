import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/fail_switch.dart';
import 'screens/lesson_detail_screen.dart';
import 'screens/my_lessons_screen.dart';
import 'screens/professor_page_screen.dart';
import 'screens/professors_screen.dart';
import 'screens/request_form_screen.dart';
import 'screens/sign_in_screen.dart';
import 'signed_in_scope.dart';

// Navigator iznad tabova. Forma za zahtev se otvara na njemu, preko celog ekrana i bez donje navigacije.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({required SessionBloc session, required Listenable refresh, FailSwitch? failSwitch}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/casovi',
    // Kad god se sesija promeni, ruter ponovo pita redirect gde korisnik sme da bude.
    refreshListenable: refresh,
    redirect: (context, state) => signInRedirect(session.state, state.uri),
    routes: [
      // Dok se ne zna da li sesija od ranije još važi.
      GoRoute(
        path: '/start',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/prijava', builder: (context, state) => const SignInScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/casovi',
                builder: (context, state) => SignedInOnly(child: MyLessonsScreen(failSwitch: failSwitch)),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        SignedInOnly(child: LessonDetailScreen(lessonId: LessonId(state.pathParameters['id']!))),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profesori',
                builder: (context, state) => ProfessorsScreen(failSwitch: failSwitch),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        ProfessorPageScreen(professorId: UserId(state.pathParameters['id']!), failSwitch: failSwitch),
                    routes: [
                      // Npr. /profesori/milica-jovanovic/zahtev?termin=s-l-srednja-0
                      // Kad se forma zatvori, tab Profesori ostaje na profilu, a ne na ekranu uspeha.
                      GoRoute(
                        path: 'zahtev',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => SignedInOnly(
                          child: RequestFormScreen(
                            professorId: UserId(state.pathParameters['id']!),
                            slotId: SlotId(state.uri.queryParameters['termin'] ?? ''),
                            failSwitch: failSwitch,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// Javno je samo ono što vidi i posetilac: lista profesora i njihovi profili. Moji časovi i slanje zahteva
// traže prijavu.
bool needsSignIn(String path) => path.startsWith('/casovi') || path.endsWith('/zahtev');

// Gde korisnik sme da bude za dato stanje sesije, ili null kad sme da ostane gde jeste.
String? signInRedirect(SessionState session, Uri location) {
  final path = location.path;
  final signedIn = session is SignedIn;

  if (session is SessionUnknown) {
    return path == '/start' ? null : '/start';
  }
  if (path == '/start') {
    return signedIn ? '/casovi' : '/profesori';
  }
  if (path == '/prijava') {
    if (!signedIn) return null;
    // Posle prijave nazad tamo odakle je učenik poslat na prijavu. Prihvata se samo adresa u aplikaciji.
    final after = location.queryParameters['posle'];
    return after != null && after.startsWith('/') ? after : '/casovi';
  }
  if (!signedIn && needsSignIn(path)) {
    return signInLocation(location);
  }
  return null;
}

String signInLocation(Uri after) => Uri(path: '/prijava', queryParameters: {'posle': after.toString()}).toString();

// Ruteru treba Listenable, a SessionBloc ima Stream. Ova klasa ih spaja.
class SessionChanges extends ChangeNotifier {
  SessionChanges(SessionBloc session) {
    _subscription = session.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<SessionState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Donja navigacija sa dva taba: Časovi i Profesori.
class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Otvoren tab tiho ponovo učita svoju listu. Tako se vidi i promena koju je u međuvremenu napravio
  // neko drugi, npr. profesor koji je u backoffice-u potvrdio čas.
  void _open(BuildContext context, int index) {
    navigationShell.goBranch(index);
    switch (index) {
      case 0 when context.read<SessionBloc>().state is SignedIn:
        context.read<MyLessonsBloc>().add(MyLessonsRefreshed());
      case 1:
        context.read<ProfessorsBloc>().add(ProfessorsRefreshed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _open(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Časovi'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Profesori'),
        ],
      ),
    );
  }
}
