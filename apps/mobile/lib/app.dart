import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'dependencies.dart';
import 'router.dart';
import 'signed_in_scope.dart';
import 'widgets/listing_title.dart';

class App extends StatefulWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Jedan za celu aplikaciju. Na pokretanju proveri da li token od ranije još važi.
  // U mobilnu smeju samo učenici; to pravilo je u domenu, u AccessPolicy.
  late final SessionBloc _session = SessionBloc(
    restoreSession: widget.dependencies.restoreSession,
    logOut: widget.dependencies.logOut,
    admits: AccessPolicy.canUseMobileApp,
    expirations: widget.dependencies.sessionExpirations,
  )..add(const SessionRestoreRequested());
  late final SessionChanges _sessionChanges = SessionChanges(_session);

  // Ruter se pravi jednom, da se ne izgubi gde je korisnik kad se App ponovo nacrta.
  late final GoRouter _router = createRouter(
    session: _session,
    refresh: _sessionChanges,
    failSwitch: widget.dependencies.failSwitch,
  );

  @override
  void dispose() {
    _router.dispose();
    _sessionChanges.dispose();
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _session),
          // Javno, pa iznad prijave. Profil profesora pravi svoj Bloc, a lista profesora je jedna za celu aplikaciju.
          RepositoryProvider(create: (context) => ListingTitles(dependencies.professors)),
          RepositoryProvider(
            create: (context) => GetProfessorPage(dependencies.professors, dependencies.lessons, dependencies.clock),
          ),
          BlocProvider(
            create: (context) => ProfessorsBloc(GetProfessors(dependencies.professors))..add(ProfessorsRequested()),
          ),
        ],
        child: BlocListener<SessionBloc, SessionState>(
          // Prijava je istekla dok je učenik bio u aplikaciji: i sa javnog ekrana ide na prijavu, gde piše zašto.
          listenWhen: (previous, current) =>
              previous is SignedIn && current is SignedOut && current.reason == SignOutReason.expired,
          listener: (context, state) => _router.go(signInLocation(_router.routerDelegate.currentConfiguration.uri)),
          child: MaterialApp.router(
            title: 'Časovi',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            // Android 12+ na kraju liste razvlači sadržaj. Ovde se to isključuje za sve liste u aplikaciji.
            scrollBehavior: const MaterialScrollBehavior().copyWith(overscroll: false),
            routerConfig: _router,
            // Iznad svih ruta, pa i forme za zahtev, koja se otvara preko tabova.
            builder: (context, child) => SessionScope(child: child!),
          ),
        ),
      ),
    );
  }
}
