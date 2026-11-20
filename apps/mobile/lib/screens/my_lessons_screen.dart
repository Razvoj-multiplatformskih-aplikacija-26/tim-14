import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../data/fail_switch.dart';
import '../text/failures.dart';
import '../widgets/lesson_card.dart';

class MyLessonsScreen extends StatelessWidget {
  const MyLessonsScreen({super.key, this.failSwitch});

  // Samo nad demo podacima. Nad serverom grešku pravi pravi server.
  final FailSwitch? failSwitch;

  void _simulateError(BuildContext context) {
    failSwitch?.failNext = true;
    context.read<MyLessonsBloc>().add(MyLessonsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji časovi'),
        actions: [
          if (failSwitch != null)
            PopupMenuButton<String>(
              onSelected: (_) => _simulateError(context),
              itemBuilder: (context) => [const PopupMenuItem(value: 'error', child: Text('Simuliraj grešku'))],
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odjava',
            onPressed: () => context.read<SessionBloc>().add(const SessionLogOutRequested()),
          ),
        ],
      ),
      body: BlocConsumer<MyLessonsBloc, MyLessonsState>(
        // Osvežavanje ili akcija nisu prošli: lista ostaje, a SnackBar kaže zašto. Kad je preko liste otvoren
        // detalj časa, poruku pokazuje detalj, pa se ovde preskače da se ne pojavi dvaput.
        listenWhen: (previous, current) => current is MyLessonsLoaded && shouldShow(current.notice),
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent ?? true) {
            final notice = (state as MyLessonsLoaded).notice!;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice.message)));
          }
        },
        builder: (context, state) {
          switch (state) {
            case MyLessonsInitial():
            case MyLessonsLoading():
              return const Center(child: CircularProgressIndicator());
            case MyLessonsFailure(:final failure):
              return _FailureView(failure: failure);
            case MyLessonsEmpty():
              return const _EmptyView();
            case MyLessonsLoaded():
              return _LessonList(state: state);
          }
        },
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.failure});

  final RepositoryFailure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.px24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: AppSpacing.px48),
            const SizedBox(height: AppSpacing.px16),
            const Text('Časovi trenutno ne mogu da se učitaju.', style: AppTextStyles.bodyBaseMedium),
            const SizedBox(height: AppSpacing.px8),
            Text(failure.message, style: AppTextStyles.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.px16),
            FilledButton(
              onPressed: () => context.read<MyLessonsBloc>().add(MyLessonsRetried()),
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.px24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note, size: AppSpacing.px48),
            const SizedBox(height: AppSpacing.px16),
            const Text('Još nemaš nijedan čas.', style: AppTextStyles.bodyBaseMedium),
            const SizedBox(height: AppSpacing.px16),
            FilledButton(onPressed: () => context.go('/profesori'), child: const Text('Zakaži čas')),
          ],
        ),
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({required this.state});

  final MyLessonsLoaded state;

  @override
  Widget build(BuildContext context) {
    // Grupe pravi stanje iz Bloc-a, ekran ih samo crta.
    final upcoming = state.upcoming;
    final pending = state.pending;
    final history = state.history;

    // Povuci nadole: tiho ponovno učitavanje, npr. posle potvrde koju je profesor napravio u backoffice-u.
    return RefreshIndicator(
      onRefresh: () {
        final done = Completer<void>();
        context.read<MyLessonsBloc>().add(MyLessonsRefreshed(done: done));
        return done.future;
      },
      child: ListView(
        // I kratka lista mora da može da se povuče.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.px16),
        children: [
          if (upcoming.isNotEmpty) ..._section(context, 'Predstojeći', upcoming),
          if (pending.isNotEmpty) ..._section(context, 'Na čekanju', pending),
          if (history.isNotEmpty) ..._section(context, 'Istorija', history),
        ],
      ),
    );
  }

  List<Widget> _section(BuildContext context, String title, List<LessonItem> items) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.px8, bottom: AppSpacing.px8),
        child: Text(title, style: AppTextStyles.headingLg),
      ),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.px8),
          child: LessonCard(lesson: item.lesson, onTap: () => context.go('/casovi/${item.lesson.id.value}')),
        ),
    ];
  }
}
