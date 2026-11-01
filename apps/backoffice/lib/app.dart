import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'data/demo_data.dart';
import 'data/fail_switch.dart';

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({
    super.key,
    required this.failSwitch,
    required this.lessons,
    required this.verifications,
    required this.router,
  });

  final FailSwitch failSwitch;
  final LessonRepository lessons;
  final VerificationRepository verifications;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    const clock = SystemClock();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: failSwitch),
        RepositoryProvider.value(value: lessons),
        RepositoryProvider.value(value: verifications),
      ],
      // Blocovi su iznad rutera, pa stanje ostaje kad se pređe na drugi deo i vrati.
      // Časovi uvek rade kao Milica, a verifikacija kao administrator. Meni samo bira koji se deo vidi.
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              final lessons = context.read<LessonRepository>();
              return LessonQueueBloc(
                GetLessonQueue(lessons, milica),
                ConfirmLesson(lessons, clock, milica),
                RejectLesson(lessons, clock, milica),
                RecordHeld(lessons, clock, milica),
                RecordNoShow(lessons, clock, milica),
              )..add(QueueRequested());
            },
          ),
          BlocProvider(
            create: (context) {
              final verifications = context.read<VerificationRepository>();
              return VerificationQueueBloc(
                GetVerificationQueue(verifications),
                VerifyProfessor(verifications, clock, admin),
                RejectProfessor(verifications, clock, admin),
              )..add(VerificationRequested());
            },
          ),
        ],
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
