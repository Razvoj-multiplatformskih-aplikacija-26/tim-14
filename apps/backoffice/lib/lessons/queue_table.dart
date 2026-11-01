import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../data/demo_data.dart';
import '../text/dates.dart';

// Isti flex za zaglavlje i redove, da kolone budu poravnate.
const _flex = (student: 3, listing: 4, start: 3, status: 3, received: 3);

// Lista redova umesto DataTable: svaki red je naš widget, pa se lako boji izbor.
// Tastaturu hvata strana oko tabele, a tabela samo crta da li je fokus na njoj.
class QueueTable extends StatelessWidget {
  const QueueTable({super.key, required this.state, required this.focused});

  final LessonQueueLoaded state;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final rows = state.visibleRows;
    const radius = BorderRadius.all(Radius.circular(AppRadius.lg));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        // Vidljiv fokus: prsten u boji ring, kao kod dugmadi.
        border: focused
            ? Border.all(color: AppColors.ring, width: 2)
            : Border.all(color: AppExtraColors.of(context).border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            const _HeaderRow(),
            const Divider(height: 1),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        'U ovom tabu nema časova.',
                        style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _QueueRowTile(row: rows[index], selected: rows[index].lesson.id == state.selectedId),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.captionXs.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.px16, vertical: AppSpacing.px12),
      child: Row(
        spacing: AppSpacing.px12,
        children: [
          Expanded(
            flex: _flex.student,
            child: Text('UČENIK', style: style),
          ),
          Expanded(
            flex: _flex.listing,
            child: Text('OGLAS', style: style),
          ),
          Expanded(
            flex: _flex.start,
            child: Text('TERMIN', style: style),
          ),
          Expanded(
            flex: _flex.status,
            child: Text('STANJE', style: style),
          ),
          Expanded(
            flex: _flex.received,
            child: Text('PRIMLJENO', style: style),
          ),
        ],
      ),
    );
  }
}

class _QueueRowTile extends StatelessWidget {
  const _QueueRowTile({required this.row, required this.selected});

  final QueueRow row;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lesson = row.lesson;
    final muted = AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant);
    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      child: InkWell(
        // Red ne uzima fokus, pa je cela tabela jedan korak za Tab, a strelice biraju red unutar nje.
        canRequestFocus: false,
        onTap: () => context.read<LessonQueueBloc>().add(RowSelected(lesson.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.px16, vertical: AppSpacing.px12),
          child: Row(
            spacing: AppSpacing.px12,
            children: [
              Expanded(
                flex: _flex.student,
                child: _Cell(
                  studentName(lesson.studentId),
                  AppTextStyles.bodySmMedium.copyWith(color: colors.onSurface),
                ),
              ),
              Expanded(
                flex: _flex.listing,
                child: _Cell(listingTitle(lesson.listingId), AppTextStyles.bodySm.copyWith(color: colors.onSurface)),
              ),
              Expanded(flex: _flex.start, child: _Cell(formatShortDateTime(lesson.start), muted)),
              Expanded(
                flex: _flex.status,
                // Align, da bedž ostane širok koliko njegov tekst, a ne cela kolona.
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LessonStatusBadge(status: lesson.status),
                ),
              ),
              Expanded(flex: _flex.received, child: _Cell(formatShortDateTime(lesson.createdAt), muted)),
            ],
          ),
        ),
      ),
    );
  }
}

// Jedan red teksta. Kad je prozor uzak, tekst se skraćuje sa „…“ umesto da izađe iz kolone.
class _Cell extends StatelessWidget {
  const _Cell(this.text, this.style);

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
  }
}
