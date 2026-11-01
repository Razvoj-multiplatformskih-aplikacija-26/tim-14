import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fail_switch.dart';
import 'router.dart';

class App extends StatefulWidget {
  const App({super.key, required this.lessons, required this.clock, required this.me, required this.failSwitch});

  final LessonRepository lessons;
  final Clock clock;
  final User me;
  final FailSwitch failSwitch;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Ruter se pravi jednom, da se ne izgubi gde je korisnik kad se App ponovo nacrta.
  late final GoRouter _router = createRouter(widget.failSwitch);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyLessonsBloc(
        GetMyLessons(widget.lessons, widget.me),
        WithdrawRequest(widget.lessons, widget.clock, widget.me),
        CancelLesson(widget.lessons, widget.clock, widget.me),
        widget.clock,
        widget.me,
      )..add(MyLessonsRequested()),
      child: MaterialApp.router(
        title: 'Časovi',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
