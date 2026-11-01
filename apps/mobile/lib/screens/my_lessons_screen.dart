import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../data/fail_switch.dart';
import '../widgets/lesson_card.dart';

class MyLessonsScreen extends StatelessWidget {
  const MyLessonsScreen({super.key, required this.failSwitch});

  final FailSwitch failSwitch;

  void _simulateError(BuildContext context) {
    failSwitch.failNext = true;
    context.read<MyLessonsBloc>().add(MyLessonsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji časovi'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => _simulateError(context),
            itemBuilder: (context) => [const PopupMenuItem(value: 'error', child: Text('Simuliraj grešku'))],
          ),
        ],
      ),
      body: BlocBuilder<MyLessonsBloc, MyLessonsState>(
        builder: (context, state) {
          switch (state) {
            case MyLessonsInitial():
            case MyLessonsLoading():
              return const Center(child: CircularProgressIndicator());
            case MyLessonsFailure():
              return const _FailureView();
            case MyLessonsEmpty():
              return const _EmptyView();
            case MyLessonsLoaded():
              return _LessonList(items: state.items);
          }
        },
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView();

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
  const _LessonList({required this.items});

  final List<LessonItem> items;

  @override
  Widget build(BuildContext context) {
    // Grupe su samo za prikaz: potvrđeni su predstojeći, na čekanju čekaju profesora, ostalo je prošlo.
    final upcoming = items.where((item) => item.lesson.status is Confirmed).toList();
    final pending = items.where((item) => item.lesson.status is Pending).toList();
    final past = items.where((item) => item.lesson.status is! Confirmed && item.lesson.status is! Pending).toList();

    // Prošli su najnoviji prvi.
    final pastNewestFirst = past.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.px16),
      children: [
        if (upcoming.isNotEmpty) ..._section(context, 'Predstojeći', upcoming),
        if (pending.isNotEmpty) ..._section(context, 'Na čekanju', pending),
        if (past.isNotEmpty) ..._section(context, 'Prošli', pastNewestFirst),
      ],
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
