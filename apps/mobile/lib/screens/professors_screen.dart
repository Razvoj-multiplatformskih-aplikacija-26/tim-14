import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../data/fail_switch.dart';
import '../text/failures.dart';
import '../widgets/professor_card.dart';

class ProfessorsScreen extends StatelessWidget {
  const ProfessorsScreen({super.key, this.failSwitch});

  // Samo nad demo podacima. Nad serverom grešku pravi pravi server.
  final FailSwitch? failSwitch;

  void _simulateError(BuildContext context) {
    failSwitch?.failNext = true;
    context.read<ProfessorsBloc>().add(ProfessorsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesori'),
        actions: [
          if (failSwitch != null)
            PopupMenuButton<String>(
              onSelected: (_) => _simulateError(context),
              itemBuilder: (context) => [const PopupMenuItem(value: 'error', child: Text('Simuliraj grešku'))],
            ),
        ],
      ),
      body: BlocConsumer<ProfessorsBloc, ProfessorsState>(
        // Osvežavanje nije stiglo do servera: lista ostaje, a SnackBar kaže zašto.
        listenWhen: (previous, current) => current is ProfessorsLoaded && current.refreshFailure != null,
        listener: (context, state) {
          final failure = (state as ProfessorsLoaded).refreshFailure!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        },
        builder: (context, state) {
          switch (state) {
            case ProfessorsInitial():
            case ProfessorsLoading():
              return const Center(child: CircularProgressIndicator());
            case ProfessorsFailure(:final failure):
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.px24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: AppSpacing.px48),
                      const SizedBox(height: AppSpacing.px16),
                      const Text('Profesori trenutno ne mogu da se učitaju.', style: AppTextStyles.bodyBaseMedium),
                      const SizedBox(height: AppSpacing.px8),
                      Text(failure.message, style: AppTextStyles.bodySm, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.px16),
                      FilledButton(
                        onPressed: () => context.read<ProfessorsBloc>().add(ProfessorsRetried()),
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                ),
              );
            case ProfessorsEmpty():
              return const Center(
                child: Text('Trenutno nema nijednog profesora.', style: AppTextStyles.bodyBaseMedium),
              );
            case ProfessorsLoaded():
              return _ProfessorList(state: state);
          }
        },
      ),
    );
  }
}

// Lista sa jednim redom više na kraju. Kad se taj red pojavi na ekranu, a sledeća strana postoji, lista je traži.
// Ekran ne zna za stranice i offset: samo javi Bloc-u da je stigao do kraja, a red na dnu crta stanje.
class _ProfessorList extends StatelessWidget {
  const _ProfessorList({required this.state});

  final ProfessorsLoaded state;

  @override
  Widget build(BuildContext context) {
    final professors = state.professors;
    // Povuci nadole: lista ponovo od prve strane, tiho.
    return RefreshIndicator(
      onRefresh: () {
        final done = Completer<void>();
        context.read<ProfessorsBloc>().add(ProfessorsRefreshed(done: done));
        return done.future;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.px16),
        itemCount: professors.length + 1,
        itemBuilder: (context, index) {
          if (index < professors.length) {
            final professor = professors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.px8),
              child: ProfessorCard(
                professor: professor,
                onTap: () => context.go('/profesori/${professor.profile.id.value}'),
              ),
            );
          }
          return _ListEnd(state: state);
        },
      ),
    );
  }
}

class _ListEnd extends StatelessWidget {
  const _ListEnd({required this.state});

  final ProfessorsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.moreFailure case final failure?) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.px16),
        child: Column(
          children: [
            Text(failure.message, style: AppTextStyles.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.px8),
            OutlinedButton(
              onPressed: () => context.read<ProfessorsBloc>().add(ProfessorsNextPageRequested()),
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }
    if (!state.hasMore) {
      return const SizedBox.shrink();
    }
    // Kraj liste je na ekranu: posle ovog crtanja tražimo sledeću stranu. Bloc ignoriše ponovljene zahteve
    // dok se strana učitava.
    if (!state.loadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<ProfessorsBloc>().add(ProfessorsNextPageRequested());
        }
      });
    }
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.px16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
