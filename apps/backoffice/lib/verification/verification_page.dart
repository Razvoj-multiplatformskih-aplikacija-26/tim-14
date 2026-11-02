import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../text/domain_errors.dart';
import '../widgets/centered_message.dart';
import 'profile_detail.dart';
import 'reject_dialog.dart';
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

class _LoadedView extends StatefulWidget {
  const _LoadedView({required this.state});

  final VerificationQueueLoaded state;

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  // Profil čiji je detalj otvoren u uskom rasporedu. Ovo zna samo ekran, pa nije u Blocu.
  // Stoji ovde, a ne u uskom rasporedu, jer ga Enter i Esc menjaju iznad Focus-a.
  UserId? _openId;

  // Posle odluke profil izlazi iz reda i Bloc bira sledeći. Tada se vraćamo na listu, gde se vidi da ga nema.
  @override
  void didUpdateWidget(_LoadedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.selectedId != _openId) _openId = null;
  }

  // Izbor i dalje drži Bloc. Ovde se samo pamti da je detalj otvoren.
  void _open(UserId id) {
    context.read<VerificationQueueBloc>().add(ProfileSelected(id));
    setState(() => _openId = id);
  }

  void _close() => setState(() => _openId = null);

  // U širokom rasporedu se ništa ne vidi, jer je detalj već pored tabele.
  void _openSelected() => setState(() => _openId = widget.state.selectedId);

  // Isti raspored tastature kao kod časova. Objašnjenja su tamo, u LessonQueuePage.
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VerificationQueueBloc>();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => bloc.add(ProfileSelectionMoved(-1)),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => bloc.add(ProfileSelectionMoved(1)),
        // Bez ponavljanja: držanje V ne verifikuje i sledećeg profesora koga Bloc izabere.
        const SingleActivator(LogicalKeyboardKey.keyV, includeRepeats: false): () => bloc.add(VerifyPressed()),
        // Dijalog je posebna ruta, nije ispod ovih prečica. Zato O i V koji se kucaju u razlog ne stižu ovde.
        const SingleActivator(LogicalKeyboardKey.keyO, includeRepeats: false): () => rejectSelected(context),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _openSelected()),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => _openSelected()),
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => _close()),
        },
        child: Focus(
          autofocus: true,
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasPrimaryFocus;
              // Izbor je u Blocu, pa ostaje isti kad se tabela zameni listom i nazad.
              return LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < _wideMinWidth
                    ? _NarrowView(
                        state: widget.state,
                        focused: focused,
                        openId: _openId,
                        onOpen: _open,
                        onClose: _close,
                      )
                    : _WideView(state: widget.state, focused: focused),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Nema tabova kao kod časova: u redu su samo profili na proveri.
class _WideView extends StatelessWidget {
  const _WideView({required this.state, required this.focused});

  final VerificationQueueLoaded state;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px24,
      children: [
        Expanded(
          child: VerificationTable(state: state, focused: focused),
        ),
        SizedBox(width: 440, child: ProfileDetail(profile: state.selected)),
      ],
    );
  }
}

// Ili lista, ili detalj preko celog prostora. Isto kao uzak raspored časova.
class _NarrowView extends StatelessWidget {
  const _NarrowView({
    required this.state,
    required this.focused,
    required this.openId,
    required this.onOpen,
    required this.onClose,
  });

  final VerificationQueueLoaded state;
  final bool focused;
  final UserId? openId;
  final ValueChanged<UserId> onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final selected = state.selected;
    if (selected == null || selected.id != openId) {
      return VerificationList(state: state, focused: focused, onOpen: onOpen);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px16,
      children: [
        Row(
          children: [
            TextButton.icon(onPressed: onClose, icon: const Icon(Icons.arrow_back), label: const Text('Nazad')),
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
