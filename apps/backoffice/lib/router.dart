import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'lessons/lesson_queue_page.dart';
import 'shell/app_shell.dart';
import 'verification/verification_page.dart';

abstract final class Routes {
  static const lessons = '/casovi';
  static const verification = '/verifikacija';
}

// Svaka uloga ima tačno jedan deo aplikacije.
String homeFor(Role role) => switch (role) {
  Role.professor => Routes.lessons,
  Role.admin => Routes.verification,
  Role.student => throw ArgumentError('Učenik ne koristi backoffice'),
};

GoRouter createRouter(ValueNotifier<User> session) {
  return GoRouter(
    initialLocation: homeFor(session.value.role),
    // Kad meni promeni korisnika, ruter ponovo pita redirect i sam prelazi na deo nove uloge.
    refreshListenable: session,
    // Jedno pravilo pokriva promenu uloge, tuđu adresu ukucanu na webu i adresu koja ne postoji.
    redirect: (context, state) {
      final home = homeFor(session.value.role);
      return state.matchedLocation == home ? null : home;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(session: session, location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: Routes.lessons, builder: (context, state) => const LessonQueuePage()),
          GoRoute(path: Routes.verification, builder: (context, state) => const VerificationPage()),
        ],
      ),
    ],
  );
}
