import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../text/domain_errors.dart';
import '../widgets/centered_message.dart';
import 'profile_detail.dart';
import 'verification_list.dart';
import 'verification_table.dart';

// Isti raspored kao Časovi: ekran samo crta stanje Bloca i šalje mu događaje.
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.px32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.px24,
        children: [
          Text('Verifikacija', style: Theme.of(context).textTheme.headlineMedium),
          Expanded(
            child: BlocConsumer<VerificationQueueBloc, VerificationQueueState>(
              listener: _showActionError,
              // Stanje je sealed, pa kompajler traži granu za svako.
              builder: (context, state) => switch (state) {
                VerificationQueueInitial() ||
                VerificationQueueLoading() => const Center(child: CircularProgressIndicator()),
                final VerificationQueueFailure failure => _FailureView(message: failure.message),
                VerificationQueueEmpty() => const _EmptyView(),
                final VerificationQueueLoaded loaded => _LoadedView(state: loaded),
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bloc pre svake odluke obriše staru grešku, pa se SnackBar pokaže jednom po grešci.
  void _showActionError(BuildContext context, VerificationQueueState state) {
    final error = state is VerificationQueueLoaded ? state.actionError : null;
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
  }
}

// Detalj je širok 440, razmak 24, a tabeli sa četiri kolone treba oko 430. Ispod toga ne staju jedno pored drugog.
const _wideMinWidth = 900.0;

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final VerificationQueueLoaded state;

  // Izbor je u Blocu, pa ostaje isti kad se tabela zameni listom i nazad.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < _wideMinWidth ? _NarrowView(state: state) : _WideView(state: state),
    );
  }
}

// Nema tabova kao kod časova: u redu su samo profili na proveri.
class _WideView extends StatelessWidget {
  const _WideView({required this.state});

  final VerificationQueueLoaded state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px24,
      children: [
        Expanded(child: VerificationTable(state: state)),
        SizedBox(width: 440, child: ProfileDetail(profile: state.selected)),
      ],
    );
  }
}

// Ili lista, ili detalj preko celog prostora. Isto kao uzak raspored časova.
class _NarrowView extends StatefulWidget {
  const _NarrowView({required this.state});

  final VerificationQueueLoaded state;

  @override
  State<_NarrowView> createState() => _NarrowViewState();
}

class _NarrowViewState extends State<_NarrowView> {
  // Profil čiji je detalj otvoren. Ovo zna samo uzak raspored, pa nije u Blocu.
  UserId? _openId;

  // Posle odluke profil izlazi iz reda i Bloc bira sledeći. Tada se vraćamo na listu, gde se vidi da ga nema.
  @override
  void didUpdateWidget(_NarrowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.selectedId != _openId) _openId = null;
  }

  // Izbor i dalje drži Bloc. Ovde se samo pamti da je detalj otvoren.
  void _open(UserId id) {
    context.read<VerificationQueueBloc>().add(ProfileSelected(id));
    setState(() => _openId = id);
  }

  void _close() => setState(() => _openId = null);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selected = state.selected;
    if (selected == null || selected.id != _openId) {
      return VerificationList(state: state, onOpen: _open);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px16,
      children: [
        Row(
          children: [
            TextButton.icon(onPressed: _close, icon: const Icon(Icons.arrow_back), label: const Text('Nazad')),
            const Spacer(),
            VerificationBadge(status: selected.verification),
          ],
        ),
        Expanded(child: ProfileDetail(profile: selected)),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CenteredMessage(
      icon: Icons.cloud_off_outlined,
      title: 'Red za verifikaciju nije učitan.',
      text: message,
      action: FilledButton(
        onPressed: () => context.read<VerificationQueueBloc>().add(VerificationRetried()),
        child: const Text('Pokušaj ponovo'),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const CenteredMessage(
      icon: Icons.verified_user_outlined,
      title: 'Nema profesora koji čekaju proveru.',
      text: 'Kad profesor pošalje diplomu i LinkedIn profil, pojaviće se ovde.',
    );
  }
}
