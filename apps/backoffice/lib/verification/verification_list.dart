import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../text/cities.dart';
import '../text/dates.dart';

// Uzak prozor dobija kartice umesto tabele, sa istim profilima iz Bloca. Isto kao lista časova.
// Klik ne bira profil sam, nego javlja roditelju, jer roditelj i bira profil i otvara detalj.
class VerificationList extends StatelessWidget {
  const VerificationList({super.key, required this.state, required this.onOpen});

  final VerificationQueueLoaded state;
  final ValueChanged<UserId> onOpen;

  @override
  Widget build(BuildContext context) {
    final profiles = state.profiles;
    return ListView.separated(
      itemCount: profiles.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.px8),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _ProfileCard(
          profile: profile,
          selected: profile.id == state.selectedId,
          onTap: () => onOpen(profile.id),
        );
      },
    );
  }
}

// Ime i stanje, dva reda o profesoru, pa grad i kad je poslato.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.selected, required this.onTap});

  final ProfessorProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.captionXs.copyWith(color: colors.onSurfaceVariant);
    final status = profile.verification;
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
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmMedium.copyWith(color: colors.onSurface),
                    ),
                  ),
                  VerificationBadge(status: status),
                ],
              ),
              Text(
                profile.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
              ),
              Row(
                spacing: AppSpacing.px8,
                children: [
                  Expanded(child: Text(profile.city.label, style: muted)),
                  if (status is AwaitingReview) Text(formatShortDateTime(status.submittedAt), style: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
