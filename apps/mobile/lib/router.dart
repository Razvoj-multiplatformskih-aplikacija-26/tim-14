import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/fail_switch.dart';
import 'screens/lesson_detail_screen.dart';
import 'screens/my_lessons_screen.dart';
import 'screens/professor_page_screen.dart';
import 'screens/professors_screen.dart';
import 'screens/request_form_screen.dart';

// Navigator iznad tabova. Forma za zahtev se otvara na njemu, preko celog ekrana i bez donje navigacije.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(FailSwitch failSwitch) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/casovi',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/casovi',
                builder: (context, state) => MyLessonsScreen(failSwitch: failSwitch),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => LessonDetailScreen(lessonId: LessonId(state.pathParameters['id']!)),
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
                        builder: (context, state) => RequestFormScreen(
                          professorId: UserId(state.pathParameters['id']!),
                          slotId: SlotId(state.uri.queryParameters['termin'] ?? ''),
                          failSwitch: failSwitch,
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

// Donja navigacija sa dva taba: Časovi i Profesori.
class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Časovi'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Profesori'),
        ],
      ),
    );
  }
}
