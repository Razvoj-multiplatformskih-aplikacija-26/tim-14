import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../text/cities.dart';
import '../text/dates.dart';
import '../widgets/detail_section.dart';
import 'reject_dialog.dart';

// Kartica desno, isti izgled kao detalj časa. README traži da administrator uporedo vidi diplomu,
// LinkedIn i podatke koje je profesor uneo, pa su sva tri u istoj kartici: prilozi jedan pored drugog, podaci ispod.
class ProfileDetail extends StatelessWidget {
  const ProfileDetail({super.key, required this.profile});

  final ProfessorProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        border: Border.all(color: AppExtraColors.of(context).border),
        boxShadow: AppShadows.sm,
      ),
      child: profile == null
          ? Center(
              child: Text(
                'Izaberite profesora iz tabele.',
                style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          // Skroluje se samo sadržaj. Dugmad su zakucana dole, pa se vide i kad je profil dugačak.
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.px24),
                    child: _Content(profile: profile),
                  ),
                ),
                const Divider(height: 1),
                // U redu su samo profili na proveri, a za njih važe obe odluke. Zato su dugmad uvek ista.
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.px24),
                  child: DetailSection(
                    title: 'ODLUKA',
                    child: Wrap(
                      spacing: AppSpacing.px8,
                      runSpacing: AppSpacing.px8,
                      children: [
                        FilledButton(
                          onPressed: () => context.read<VerificationQueueBloc>().add(VerifyPressed()),
                          child: const Text('Verifikuj'),
                        ),
                        OutlinedButton(onPressed: () => rejectSelected(context), child: const Text('Odbij uz razlog')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.profile});

  final ProfessorProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant);
    final status = profile.verification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px24,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.px12,
          children: [
            Avatar(name: profile.fullName),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.px4,
                children: [
                  Text(profile.fullName, style: AppTextStyles.headingXl.copyWith(color: colors.onSurface)),
                  Text(profile.city.label, style: muted),
                  if (status is AwaitingReview) Text('Poslato ${formatDateTime(status.submittedAt)}', style: muted),
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
            child: Text(profile.bio, style: AppTextStyles.bodyBase.copyWith(color: colors.onSurface)),
          ),
        ),
        // Prilozi postoje samo dok profil čeka proveru, zato provera pre čitanja.
        if (status is AwaitingReview)
          DetailSection(
            title: 'PRILOZI',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.px12,
              children: [
                Expanded(
                  child: _Attachment(icon: Icons.description_outlined, label: 'Diploma', value: status.diplomaFile),
                ),
                Expanded(
                  child: _Attachment(icon: Icons.link, label: 'LinkedIn', value: status.linkedIn.value),
                ),
              ],
            ),
          ),
        DetailSection(
          title: 'OBRAZOVANJE',
          child: _Entries([
            for (final education in profile.education)
              _Entry(
                title: education.title,
                place: education.institution,
                years: formatYears(education.fromYear, education.toYear),
              ),
          ]),
        ),
        DetailSection(
          title: 'ISKUSTVO',
          child: _Entries([
            for (final job in profile.experience)
              _Entry(title: job.title, place: job.employer, years: formatYears(job.fromYear, job.toYear)),
          ]),
        ),
      ],
    );
  }
}

// Jedan prilog: diploma ili LinkedIn. U KT1 su to samo ime fajla i adresa kao tekst.
class _Attachment extends StatelessWidget {
  const _Attachment({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppExtraColors.of(context).border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.px12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.px4,
          children: [
            Row(
              spacing: AppSpacing.px4,
              children: [
                Icon(icon, size: 16, color: colors.onSurfaceVariant),
                Text(label, style: AppTextStyles.captionXs.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
            Text(value, style: AppTextStyles.bodySm.copyWith(color: colors.onSurface)),
          ],
        ),
      ),
    );
  }
}

// Spisak škola ili poslova. Profesor ne mora ništa da unese, pa i prazan spisak ima tekst.
class _Entries extends StatelessWidget {
  const _Entries(this.entries);

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'Nije uneto.',
        style: AppTextStyles.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.px12, children: entries);
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.title, required this.place, required this.years});

  final String title;
  final String place;
  final String years;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.px12,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.px4,
            children: [
              Text(title, style: AppTextStyles.bodySmMedium.copyWith(color: colors.onSurface)),
              Text(place, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
        Text(years, style: AppTextStyles.captionXs.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}
