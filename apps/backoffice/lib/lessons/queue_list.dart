import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../data/demo_data.dart';
import '../text/dates.dart';

// Figma: „Poruke · mobile lista“. Uzak prozor dobija kartice umesto tabele, sa istim redovima iz Bloca.
// Klik ne bira red sam, nego javlja roditelju, jer roditelj i bira red i otvara detalj.
class QueueList extends StatelessWidget {
  const QueueList({super.key, required this.state, required this.onOpen});

  final LessonQueueLoaded state;
  final ValueChanged<LessonId> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = state.visibleRows;
    if (rows.isEmpty) {
      return Center(
        child: Text(
          'U ovom tabu nema časova.',
          style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.px8),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _QueueCard(row: row, selected: row.lesson.id == state.selectedId, onTap: () => onOpen(row.lesson.id));
      },
    );
  }
}

// Figma: Panel/InboxRow. Ime i stanje, dva reda poruke, pa oglas i termin.
class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.row, required this.selected, required this.onTap});

  final QueueRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lesson = row.lesson;
    final muted = AppTextStyles.captionXs.copyWith(color: colors.onSurfaceVariant);
    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        side: BorderSide(color: AppExtraColors.of(context).border),
      ),
      clipBehavior: Clip.antiAlias,
      // InkWell može da dobije fokus i sam pokreće onTap na Enter i razmak, pa Tab + Enter otvara detalj.
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.px12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.px4,
            children: [
              Row(
                spacing: AppSpacing.px8,
                children: [
                  Expanded(
                    child: Text(
                      studentName(lesson.studentId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmMedium.copyWith(color: colors.onSurface),
                    ),
                  ),
                  LessonStatusBadge(status: lesson.status),
                ],
              ),
              Text(
                lesson.message.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
              Row(
                spacing: AppSpacing.px8,
                children: [
                  Expanded(
                    child: Text(
                      listingTitle(lesson.listingId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                  Text(formatShortDateTime(lesson.start), style: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
