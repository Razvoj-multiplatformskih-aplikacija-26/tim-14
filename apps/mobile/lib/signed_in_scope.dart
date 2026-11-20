import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:use_cases/use_cases.dart';

import 'dependencies.dart';

// Bira da li ispod stoji SignedInScope. Menja se samo kad se promeni prijavljeni korisnik,
// ne i kad se promeni razlog odjave.
class SessionScope extends StatelessWidget {
  const SessionScope({super.key, required this.child});

  final Widget child;

  static UserId? _userOf(SessionState state) => state is SignedIn ? state.user.id : null;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      buildWhen: (previous, current) => _userOf(previous) != _userOf(current),
      builder: (context, session) => switch (session) {
        SignedIn(:final user) => SignedInScope(key: ValueKey(user.id), user: user, child: child),
        _ => child,
      },
    );
  }
}

// Sve što važi samo za prijavljenog učenika: njegovi časovi i slanje zahteva u njegovo ime.
// Ključ je id korisnika, pa se posle odjave Bloc zatvori, a sledeći korisnik dobije nov i ne vidi tuđe časove.
class SignedInScope extends StatelessWidget {
  const SignedInScope({super.key, required this.user, required this.child});

  final User user;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dependencies = context.read<AppDependencies>();
    final lessons = dependencies.lessons;
    final clock = dependencies.clock;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          // Odmah, a ne tek kad se otvori ekran: otvaranje taba onda samo osveži listu koja već postoji.
          lazy: false,
          create: (context) => MyLessonsBloc(
            GetMyLessons(lessons, user),
            WithdrawRequest(lessons, clock, user),
            CancelLesson(lessons, clock, user),
            clock,
            user,
          )..add(MyLessonsRequested()),
        ),
        RepositoryProvider(create: (context) => RequestLesson(lessons, dependencies.professors, clock, user)),
      ],
      child: child,
    );
  }
}

// Ekran koji traži prijavu. Posle odjave ili isteka on nestane u istom frejmu kad i SignedInScope, pa nikad ne traži
// Bloc koji je upravo zatvoren. Ruter ga zatim vodi na prijavu.
class SignedInOnly extends StatelessWidget {
  const SignedInOnly({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<SessionBloc, bool>((session) => session.state is SignedIn);
    return signedIn ? child : const SizedBox.shrink();
  }
}
