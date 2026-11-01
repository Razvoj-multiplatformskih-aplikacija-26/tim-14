import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../data/demo_data.dart';
import '../text/dates.dart';
import '../widgets/detail_section.dart';
import 'timeline.dart';

// Figma: kartica desno u „Poruke · split“. Pokazuje izabrani red: poruku, tok i dugmad.
class LessonDetail extends StatelessWidget {
  const LessonDetail({super.key, required this.row});

  final QueueRow? row;

  @override
  Widget build(BuildContext context) {
    final row = this.row;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        border: Border.all(color: AppExtraColors.of(context).border),
        boxShadow: AppShadows.sm,
      ),
      child: row == null
          ? Center(
              child: Text(
                'Izaberite čas iz tabele.',
                style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          // Skroluje se samo sadržaj. Dugmad su zakucana dole, pa se vide i kad je poruka dugačka.
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.px24),
                    child: _Content(row: row),
                  ),
                ),
                // Bloc za svaki red kaže koja dugmad nudi. Arhiva ih nema, pa nema ni trake.
                if (row.actions.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.px24),
                    child: DetailSection(
                      title: 'PROMENI STATUS',
                      child: Wrap(
                        spacing: AppSpacing.px8,
                        runSpacing: AppSpacing.px8,
                        children: [for (final action in row.actions) _ActionButton(action: action)],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.row});

  final QueueRow row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lesson = row.lesson;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px24,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.px12,
          children: [
            Avatar(name: studentName(lesson.studentId)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.px4,
                children: [
                  Text(studentName(lesson.studentId), style: AppTextStyles.headingXl.copyWith(color: colors.onSurface)),
                  Text(
                    '${formatDateTime(lesson.start)} · ${lesson.duration.minutes} min',
                    style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    listingTitle(lesson.listingId),
                    style: AppTextStyles.bodySm.copyWith(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppExtraColors.of(context).muted,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.px16),
            child: Text(lesson.message.text, style: AppTextStyles.bodyBase.copyWith(color: colors.onSurface)),
          ),
        ),
        DetailSection(
          title: 'TOK',
          child: Column(
            spacing: AppSpacing.px8,
            children: [for (final step in timelineOf(lesson)) _TimelineLine(step: step)],
          ),
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine({required this.step});

  final TimelineStep step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extra = AppExtraColors.of(context);
    final at = step.at;
    return Row(
      spacing: AppSpacing.px12,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: step.done ? extra.verified : extra.border, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            step.label,
            style: AppTextStyles.bodySm.copyWith(color: step.done ? colors.onSurface : colors.onSurfaceVariant),
          ),
        ),
        Text(
          at == null ? '—' : formatDateTime(at),
          style: AppTextStyles.captionXs.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// Dugme samo šalje događaj. Koji čas menja, Bloc zna iz izabranog reda.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final QueueAction action;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LessonQueueBloc>();
    return switch (action) {
      QueueAction.confirm => FilledButton(onPressed: () => bloc.add(ConfirmPressed()), child: const Text('Potvrdi')),
      QueueAction.reject => OutlinedButton(onPressed: () => bloc.add(RejectPressed()), child: const Text('Odbij')),
      QueueAction.held => FilledButton(
        onPressed: () => bloc.add(HeldPressed()),
        child: const Text('Označi kao održan'),
      ),
      QueueAction.noShow => FilledButton(
        style: AppButtonStyles.destructive,
        onPressed: () => bloc.add(NoShowPressed()),
        child: const Text('Označi kao neodržan'),
      ),
    };
  }
}
