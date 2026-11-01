import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../data/demo_data.dart';
import '../text/dates.dart';
import '../text/domain_errors.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final LessonId lessonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalj časa')),
      body: BlocConsumer<MyLessonsBloc, MyLessonsState>(
        // Ako akcija ne prođe, Bloc vrati grešku u actionError, a mi je prikažemo kao SnackBar.
        listenWhen: (previous, current) => current is MyLessonsLoaded && current.actionError != null,
        listener: (context, state) {
          final error = (state as MyLessonsLoaded).actionError!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        },
        builder: (context, state) {
          switch (state) {
            case MyLessonsInitial():
            case MyLessonsLoading():
              return const Center(child: CircularProgressIndicator());
            case MyLessonsFailure():
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Čas trenutno ne može da se učita.', style: AppTextStyles.bodyBaseMedium),
                    const SizedBox(height: AppSpacing.px16),
                    FilledButton(
                      onPressed: () => context.read<MyLessonsBloc>().add(MyLessonsRetried()),
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              );
            case MyLessonsEmpty():
              return const Center(child: Text('Ovaj čas ne postoji.'));
            case MyLessonsLoaded():
              for (final item in state.items) {
                if (item.lesson.id == lessonId) {
                  return _LessonDetail(item: item);
                }
              }
              return const Center(child: Text('Ovaj čas ne postoji.'));
          }
        },
      ),
    );
  }
}

class _LessonDetail extends StatelessWidget {
  const _LessonDetail({required this.item});

  final LessonItem item;

  @override
  Widget build(BuildContext context) {
    final lesson = item.lesson;
    final professorName = professorNames[lesson.professorId] ?? 'Profesor';
    final listingTitle = listingTitles[lesson.listingId] ?? '';
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.px16),
      children: [
        Row(
          children: [
            Avatar(name: professorName, size: AvatarSize.lg),
            const SizedBox(width: AppSpacing.px16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(professorName, style: AppTextStyles.headingLg),
                  const SizedBox(height: AppSpacing.px2),
                  Text(listingTitle, style: AppTextStyles.bodySm.copyWith(color: mutedColor)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.px16),
        Align(
          alignment: Alignment.centerLeft,
          child: LessonStatusBadge(status: lesson.status),
        ),
        const SizedBox(height: AppSpacing.px24),
        _InfoRow(label: 'Termin', value: formatLessonTime(lesson.start)),
        _InfoRow(label: 'Trajanje', value: '${lesson.duration.minutes} min'),
        _InfoRow(label: 'Tvoja poruka', value: lesson.message.text),
        const SizedBox(height: AppSpacing.px16),
        const Text('Tok', style: AppTextStyles.headingLg),
        const SizedBox(height: AppSpacing.px8),
        _StepRow(text: 'Zahtev poslat', time: lesson.createdAt),
        _statusStep(lesson.status),
        const SizedBox(height: AppSpacing.px24),
        _ActionButton(item: item),
      ],
    );
  }

  // Poslednji korak u toku zavisi od stanja časa.
  Widget _statusStep(LessonStatus status) {
    switch (status) {
      case Pending():
        return const _StepRow(text: 'Čeka se odgovor profesora');
      case Confirmed(:final at):
        return _StepRow(text: 'Profesor je potvrdio čas', time: at);
      case Held(:final at):
        return _StepRow(text: 'Čas je održan', time: at);
      case Cancelled(:final at):
        return _StepRow(text: 'Čas je otkazan', time: at);
      case Rejected(cause: RejectionCause.slotTaken, :final at):
        return _StepRow(text: 'Termin je dobio drugi učenik', time: at);
      case Rejected(:final at):
        return _StepRow(text: 'Profesor je odbio zahtev', time: at);
      case NoShow(:final at):
        return _StepRow(text: 'Nisi došao na čas', time: at);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.px12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.captionXs.copyWith(color: mutedColor)),
          const SizedBox(height: AppSpacing.px2),
          Text(value, style: AppTextStyles.bodyBase),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.text, this.time});

  final String text;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.px8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.px4),
            child: Icon(Icons.circle, size: AppSpacing.px8),
          ),
          const SizedBox(width: AppSpacing.px12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: AppTextStyles.bodySm),
                if (time != null)
                  Text(formatLessonTime(time!), style: AppTextStyles.captionXs.copyWith(color: mutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.item});

  final LessonItem item;

  Future<void> _confirmAndRun(BuildContext context) async {
    final isWithdraw = item.action == LessonAction.withdraw;

    // Povlačenje i otkazivanje ne mogu da se ponište, pa prvo pitamo.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isWithdraw ? 'Povući zahtev?' : 'Otkazati čas?'),
        content: const Text('Ova radnja ne može da se poništi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Odustani')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isWithdraw ? 'Da, povuci' : 'Da, otkaži'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final bloc = context.read<MyLessonsBloc>();
    if (isWithdraw) {
      bloc.add(LessonWithdrawn(item.lesson));
    } else {
      bloc.add(LessonCancelled(item.lesson));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (item.action == LessonAction.none) {
      return const SizedBox.shrink();
    }

    final label = item.action == LessonAction.withdraw ? 'Povuci zahtev' : 'Otkaži čas';
    final blockedBy = item.blockedBy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ako akcija nije dozvoljena, dugme je sivo (onPressed je null).
        OutlinedButton(onPressed: blockedBy == null ? () => _confirmAndRun(context) : null, child: Text(label)),
        if (blockedBy != null) ...[
          const SizedBox(height: AppSpacing.px8),
          Text(
            blockedBy.message,
            style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
