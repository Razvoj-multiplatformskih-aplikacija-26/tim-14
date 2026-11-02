import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../data/fail_switch.dart';
import '../widgets/professor_card.dart';

class ProfessorsScreen extends StatelessWidget {
  const ProfessorsScreen({super.key, required this.failSwitch});

  final FailSwitch failSwitch;

  void _simulateError(BuildContext context) {
    failSwitch.failNext = true;
    context.read<ProfessorsBloc>().add(ProfessorsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesori'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => _simulateError(context),
            itemBuilder: (context) => [const PopupMenuItem(value: 'error', child: Text('Simuliraj grešku'))],
          ),
        ],
      ),
      body: BlocBuilder<ProfessorsBloc, ProfessorsState>(
        builder: (context, state) {
          switch (state) {
            case ProfessorsInitial():
            case ProfessorsLoading():
              return const Center(child: CircularProgressIndicator());
            case ProfessorsFailure():
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.px24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: AppSpacing.px48),
                      const SizedBox(height: AppSpacing.px16),
                      const Text('Profesori trenutno ne mogu da se učitaju.', style: AppTextStyles.bodyBaseMedium),
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
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.px16),
                children: [
                  for (final professor in state.professors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.px8),
                      // Klik vodi na profil profesora, koji stiže u sledećem koraku.
                      child: ProfessorCard(professor: professor),
                    ),
                ],
              );
          }
        },
      ),
    );
  }
}
