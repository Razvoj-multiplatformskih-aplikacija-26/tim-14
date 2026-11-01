import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../text/cities.dart';
import '../text/dates.dart';

// Isti flex za zaglavlje i redove, da kolone budu poravnate.
const _flex = (name: 4, city: 3, submitted: 3, status: 3);

// Ista ideja kao tabela časova: lista naših redova umesto DataTable.
class VerificationTable extends StatelessWidget {
  const VerificationTable({super.key, required this.state});

  final VerificationQueueLoaded state;

  @override
  Widget build(BuildContext context) {
    final profiles = state.profiles;
    const radius = BorderRadius.all(Radius.circular(AppRadius.lg));
    // Prazan red Bloc javlja kao posebno stanje, pa ovde uvek ima bar jedan profil.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: AppExtraColors.of(context).border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            const _HeaderRow(),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: profiles.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _ProfileRowTile(profile: profiles[index], selected: profiles[index].id == state.selectedId),
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
            flex: _flex.name,
            child: Text('IME', style: style),
          ),
          Expanded(
            flex: _flex.city,
            child: Text('GRAD', style: style),
          ),
          Expanded(
            flex: _flex.submitted,
            child: Text('POSLATO', style: style),
          ),
          Expanded(
            flex: _flex.status,
            child: Text('STANJE', style: style),
          ),
        ],
      ),
    );
  }
}

class _ProfileRowTile extends StatelessWidget {
  const _ProfileRowTile({required this.profile, required this.selected});

  final ProfessorProfile profile;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant);
    // U redu su samo profili na proveri, ali tip to ne zna. Zato provera pre čitanja datuma.
    final status = profile.verification;
    final submitted = status is AwaitingReview ? formatShortDateTime(status.submittedAt) : '—';
    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: () => context.read<VerificationQueueBloc>().add(ProfileSelected(profile.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.px16, vertical: AppSpacing.px12),
          child: Row(
            spacing: AppSpacing.px12,
            children: [
              Expanded(
                flex: _flex.name,
                child: _Cell(profile.fullName, AppTextStyles.bodySmMedium.copyWith(color: colors.onSurface)),
              ),
              Expanded(
                flex: _flex.city,
                child: _Cell(profile.city.label, AppTextStyles.bodySm.copyWith(color: colors.onSurface)),
              ),
              Expanded(flex: _flex.submitted, child: _Cell(submitted, muted)),
              Expanded(
                flex: _flex.status,
                // Align, da bedž ostane širok koliko njegov tekst, a ne cela kolona.
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VerificationBadge(status: profile.verification),
                ),
              ),
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
