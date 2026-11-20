import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'dependencies.dart';

// Isti SessionBloc za main i za testove. Ko sme u backoffice ne odlučuje aplikacija, nego pravilo iz domena.
SessionBloc createSessionBloc(SessionRepository sessions) => SessionBloc(
  restoreSession: RestoreSession(sessions),
  logOut: LogOut(sessions),
  admits: AccessPolicy.canUseBackoffice,
  expirations: sessions.expirations,
);

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key, required this.dependencies, required this.session, required this.router});

  final BackofficeDependencies dependencies;
  final SessionBloc session;
  final GoRouter router;

  // Ovde su samo stvari koje žive dok radi aplikacija: repozitorijumi i sesija.
  // Blocovi za časove i verifikaciju su niže, u SignedInScope, jer pripadaju jednom prijavljenom korisniku.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider.value(
        value: session,
        child: MaterialApp.router(
          title: 'Backoffice',
          theme: buildAppTheme(),
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
