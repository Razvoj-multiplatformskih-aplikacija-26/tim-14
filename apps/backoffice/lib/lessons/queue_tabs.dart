import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

// Figma: tabovi iznad liste u „Poruke · split“. Nije Material TabBar, jer on čuva izabrani tab u svom kontroleru,
// a ovde tab čuva Bloc. Klik samo šalje TabChanged.
class QueueTabs extends StatelessWidget {
  const QueueTabs({super.key, required this.state});

  final LessonQueueLoaded state;

  // Tabovi su široki oko 440 px. Kad strana nema toliko mesta, skroluju se levo-desno umesto da izađu iz ekrana.
  // Na širokom prozoru skrol je tačno veličine tabova, pa se ništa ne menja.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppExtraColors.of(context).muted,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.px4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.px4,
            children: [
              for (final tab in QueueTab.values)
                _Tab(tab: tab, count: state.rows.where((row) => row.tab == tab).length, selected: tab == state.tab),
            ],
          ),
        ),
      ),
    );
  }
}

String _label(QueueTab tab) => switch (tab) {
  QueueTab.pending => 'Na čekanju',
  QueueTab.confirmed => 'Potvrđeni',
  QueueTab.held => 'Održani',
  QueueTab.archive => 'Arhiva',
};

class _Tab extends StatelessWidget {
  const _Tab({required this.tab, required this.count, required this.selected});

  final QueueTab tab;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(AppRadius.md));
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: selected ? AppShadows.sm : null),
      child: Material(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => context.read<LessonQueueBloc>().add(TabChanged(tab)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.px16, vertical: AppSpacing.px8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: AppSpacing.px8,
              children: [
                Text(
                  _label(tab),
                  style: AppTextStyles.bodySmMedium.copyWith(
                    color: selected ? colors.onSurface : colors.onSurfaceVariant,
                  ),
                ),
                Text('$count', style: AppTextStyles.captionXs.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
