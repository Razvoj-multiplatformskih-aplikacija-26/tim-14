import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../dependencies.dart';
import '../text/failures.dart';
import '../text/session.dart';

// Zajednički LoginScreen iz ui paketa, povezan sa Blocovima. Sam ekran ne zna za Blocove.
// LoginFormBloc živi samo dok je ova strana otvorena. Posle prijave ruter je skloni, pa se i Bloc zatvori.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LoginFormBloc(LogIn(context.read<BackofficeDependencies>().sessions), context.read<SessionBloc>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    // watch: ekran se ponovo crta kad se promeni forma ili sesija.
    final form = context.watch<LoginFormBloc>().state;
    final session = context.watch<SessionBloc>().state;
    final reason = session is SignedOut ? session.reason : null;

    return LoginScreen(
      title: 'Backoffice',
      subtitle: 'Prijava za profesore i administratore',
      busy: form is LoginSubmitting,
      errorText: switch (form) {
        LoginIdle() || LoginSubmitting() => null,
        LoginRejected() => wrongCredentialsText,
        final LoginFailed failed => failed.failure.message,
      },
      // Razlog dolaska (istek, učenik, server) stoji samo dok forma miruje. Novi pokušaj ga skloni.
      noticeText: form is LoginIdle ? reason?.notice : null,
      onSubmit: (login, password) =>
          context.read<LoginFormBloc>().add(LoginSubmitted(login: login, password: password)),
    );
  }
}
