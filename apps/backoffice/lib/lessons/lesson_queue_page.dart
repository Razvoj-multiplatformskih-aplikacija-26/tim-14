import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../text/domain_errors.dart';
import 'lesson_detail.dart';
import 'queue_table.dart';
import 'queue_tabs.dart';

// Ekran samo crta stanje Bloca i šalje mu događaje. Nijedno pravilo nije ovde.
class LessonQueuePage extends StatelessWidget {
  const LessonQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.px32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.px24,
        children: [
          Text('Časovi', style: Theme.of(context).textTheme.headlineMedium),
          Expanded(
            // listener je za jednokratne stvari kao SnackBar, builder crta ekran za svako stanje.
            child: BlocConsumer<LessonQueueBloc, LessonQueueState>(
              listener: _showActionError,
              // Stanje je sealed, pa kompajler traži granu za svako. Novo stanje u Blocu ne prolazi dok se ne nacrta.
              builder: (context, state) => switch (state) {
                LessonQueueInitial() || LessonQueueLoading() => const Center(child: CircularProgressIndicator()),
                final LessonQueueFailure failure => _FailureView(message: failure.message),
                LessonQueueEmpty() => const _EmptyView(),
                final LessonQueueLoaded loaded => _LoadedView(state: loaded),
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bloc pre svake akcije obriše staru grešku, pa je svaka greška novo stanje i SnackBar se pokaže jednom.
  void _showActionError(BuildContext context, LessonQueueState state) {
    final error = state is LessonQueueLoaded ? state.actionError : null;
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final LessonQueueLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.px16,
      children: [
        QueueTabs(state: state),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.px24,
            children: [
              Expanded(child: QueueTable(state: state)),
              SizedBox(width: 380, child: LessonDetail(row: state.selected)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.cloud_off_outlined,
      title: 'Časovi nisu učitani.',
      text: message,
      action: FilledButton(
        onPressed: () => context.read<LessonQueueBloc>().add(QueueRetried()),
        child: const Text('Pokušaj ponovo'),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const _CenteredMessage(
      icon: Icons.event_available_outlined,
      title: 'Još nema zahteva za časove.',
      text: 'Kad učenik zatraži termin iz vašeg oglasa, zahtev će se pojaviti ovde.',
    );
  }
}

// Zajednički izgled za grešku i prazan ekran.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.title, required this.text, this.action});

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.px12,
        children: [
          Icon(icon, size: 40, color: colors.onSurfaceVariant),
          Text(title, style: AppTextStyles.headingLg.copyWith(color: colors.onSurface)),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
          ),
          ?action,
        ],
      ),
    );
  }
}
