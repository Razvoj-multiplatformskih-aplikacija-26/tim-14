import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../data/fail_switch.dart';
import '../text/catalog.dart';
import '../text/dates.dart';

class ProfessorPageScreen extends StatelessWidget {
  const ProfessorPageScreen({super.key, required this.professorId, required this.failSwitch});

  final UserId professorId;
  final FailSwitch failSwitch;

  @override
  Widget build(BuildContext context) {
    // Svaki profil ima svoj Bloc, koji se zatvori kad se izađe sa ekrana.
    return BlocProvider(
      create: (context) =>
          ProfessorPageBloc(context.read<GetProfessorPage>(), professorId)..add(ProfessorPageRequested()),
      child: _ProfessorPageView(failSwitch: failSwitch),
    );
  }
}

class _ProfessorPageView extends StatelessWidget {
  const _ProfessorPageView({required this.failSwitch});

  final FailSwitch failSwitch;

  void _simulateError(BuildContext context) {
    failSwitch.failNext = true;
    context.read<ProfessorPageBloc>().add(ProfessorPageRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil profesora'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => _simulateError(context),
            itemBuilder: (context) => [const PopupMenuItem(value: 'error', child: Text('Simuliraj grešku'))],
          ),
        ],
      ),
      body: BlocBuilder<ProfessorPageBloc, ProfessorPageState>(
        builder: (context, state) {
          switch (state) {
            case ProfessorPageInitial():
            case ProfessorPageLoading():
              return const Center(child: CircularProgressIndicator());
            case ProfessorPageFailure():
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.px24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: AppSpacing.px48),
                      const SizedBox(height: AppSpacing.px16),
                      const Text('Profil trenutno ne može da se učita.', style: AppTextStyles.bodyBaseMedium),
                      const SizedBox(height: AppSpacing.px16),
                      FilledButton(
                        onPressed: () => context.read<ProfessorPageBloc>().add(ProfessorPageRetried()),
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                ),
              );
            case ProfessorPageLoaded():
              return _ProfessorDetails(page: state.page);
          }
        },
      ),
    );
  }
}

class _ProfessorDetails extends StatelessWidget {
  const _ProfessorDetails({required this.page});

  final ProfessorPage page;

  @override
  Widget build(BuildContext context) {
    final profile = page.profile;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.px16),
      children: [
        Row(
          children: [
            Avatar(name: profile.fullName, size: AvatarSize.lg),
            const SizedBox(width: AppSpacing.px16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName, style: AppTextStyles.headingLg),
                  const SizedBox(height: AppSpacing.px2),
                  Text(profile.city.label, style: AppTextStyles.bodySm.copyWith(color: mutedColor)),
                  if (profile.isVerified) ...[
                    const SizedBox(height: AppSpacing.px8),
                    const AppBadge(label: 'Diploma potvrđena', tone: BadgeTone.verified),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.px16),
          Text(profile.bio, style: AppTextStyles.bodyBase),
        ],
        const SizedBox(height: AppSpacing.px24),
        const Text('Oglasi i slobodni termini', style: AppTextStyles.headingLg),
        const SizedBox(height: AppSpacing.px8),
        if (page.listings.isEmpty) const Text('Profesor još nema nijedan oglas.', style: AppTextStyles.bodySm),
        for (final listing in page.listings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.px8),
            child: _ListingCard(listing: listing, slots: page.freeSlotsOf(listing.id)),
          ),
      ],
    );
  }
}

// Jedan oglas i ispod njega njegovi slobodni termini.
class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.slots});

  final Listing listing;
  final List<Slot> slots;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.px16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(listing.description, style: AppTextStyles.bodyBaseMedium),
            const SizedBox(height: AppSpacing.px2),
            Text(
              '${listing.subject.label} · ${listing.level.label} · ${listing.city.label}',
              style: AppTextStyles.bodySm.copyWith(color: mutedColor),
            ),
            const SizedBox(height: AppSpacing.px8),
            Text('${formatPrice(listing.price)} / ${listing.duration.minutes} min', style: AppTextStyles.bodySmMedium),
            const SizedBox(height: AppSpacing.px12),
            if (slots.isEmpty)
              Text('Nema slobodnih termina.', style: AppTextStyles.bodySm.copyWith(color: mutedColor))
            else
              Wrap(
                spacing: AppSpacing.px8,
                runSpacing: AppSpacing.px8,
                children: [
                  for (final slot in slots)
                    ActionChip(
                      label: Text(formatSlotTime(slot.start)),
                      onPressed: () =>
                          context.go('/profesori/${slot.professorId.value}/zahtev?termin=${slot.id.value}'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
