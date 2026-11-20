import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../text/session.dart';

// Prijava učenika. Forma predaje korisnika SessionBloc-u, a kuda posle toga ruter odlučuje sam (?posle=).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginFormBloc(context.read<AppDependencies>().logIn, context.read<SessionBloc>()),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    final form = context.watch<LoginFormBloc>().state;
    final session = context.watch<SessionBloc>().state;
    final reason = session is SignedOut ? session.reason : null;

    return LoginScreen(
      title: 'Časovi',
      subtitle: 'Prijavi se da zakažeš čas i vidiš svoje časove.',
      busy: form is LoginSubmitting,
      errorText: loginErrorText(form),
      noticeText: reason?.message,
      // Profesori i njihovi profili su javni, pa se sa prijave uvek može nazad na njih.
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/profesori')),
        title: const Text('Prijava'),
      ),
      onSubmit: (login, password) =>
          context.read<LoginFormBloc>().add(LoginSubmitted(login: login, password: password)),
    );
  }
}
