import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../text/domain_errors.dart';
import '../widgets/centered_message.dart';
import 'lesson_detail.dart';
import 'queue_list.dart';
import 'queue_table.dart';
import 'queue_tabs.dart';

// Ekran samo crta stanje Bloca i šalje mu događaje. Nijedno pravilo nije ovde.
class LessonQueuePage extends StatelessWidget {
  const LessonQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.px32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.px24,
        children: [
          Text('Časovi', style: Theme.of(context).textTheme.headlineMedium),
          Expanded(
            // listener je za jednokratne stvari kao SnackBar, builder crta ekran za svako stanje.
            child: BlocConsumer<LessonQueueBloc, LessonQueueState>(
              listener: _showActionError,
              // Stanje je sealed, pa kompajler traži granu za svako. Novo stanje u Blocu ne prolazi dok se ne nacrta.
              builder: (context, state) => switch (state) {
                LessonQueueInitial() || LessonQueueLoading() => const Center(child: CircularProgressIndicator()),
                final LessonQueueFailure failure => _FailureView(message: failure.message),
                LessonQueueEmpty() => const _EmptyView(),
                final LessonQueueLoaded loaded => _LoadedView(state: loaded),
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bloc pre svake akcije obriše staru grešku, pa je svaka greška novo stanje i SnackBar se pokaže jednom.
  void _showActionError(BuildContext context, LessonQueueState state) {
    final error = state is LessonQueueLoaded ? state.actionError : null;
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
  }
}

// Detalj je širok 380, razmak 24, a tabeli treba oko 500. Ispod toga ne staju jedno pored drugog.
const _wideMinWidth = 900.0;

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final LessonQueueLoaded state;

  // LayoutBuilder meri prostor koji strana dobije, ne ceo prozor. Uz sidebar lista se pojavi kad je prozor uži od ~1212 px.
  // Izbor je u Blocu, pa ostaje isti kad se tabela zameni listom i nazad.
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LessonQueueBloc>();
    // Taster šalje isti događaj kao dugme. Koji red menja, Bloc zna iz izbora.
    // Prečice čuju taster samo kad je fokus negde ispod njih, zato Focus ispod.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => bloc.add(SelectionMoved(-1)),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => bloc.add(SelectionMoved(1)),
        // Bez ponavljanja: držanje P ne potvrdi i sledeći zahtev koji Bloc izabere.
        const SingleActivator(LogicalKeyboardKey.keyP, includeRepeats: false): () => bloc.add(ConfirmPressed()),
        const SingleActivator(LogicalKeyboardKey.keyO, includeRepeats: false): () => bloc.add(RejectPressed()),
      },
      // autofocus: tasteri rade čim se tabela pojavi, bez klika.
      // Focus je iznad LayoutBuilder-a, pa ostaje isti kad se tabela zameni listom.
      child: Focus(
        autofocus: true,
        // Builder daje context ispod Focus-a, pa Focus.of vidi baš ovaj čvor i crta ponovo kad se fokus promeni.
        child: Builder(
          builder: (context) {
            // Samo kad fokus drži baš ovaj čvor. Kad je na dugmetu, prsten crta dugme.
            final focused = Focus.of(context).hasPrimaryFocus;
            return LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < _wideMinWidth
                  ? _NarrowView(state: state)
                  : _WideView(state: state, focused: focused),
            );
          },
        ),
      ),
    );
  }
}

class _WideView extends StatelessWidget {
  const _WideView({required this.state, required this.focused});

  final LessonQueueLoaded state;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.px16,
      children: [
        QueueTabs(state: state),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.px24,
            children: [
              Expanded(
                child: QueueTable(state: state, focused: focused),
              ),
              SizedBox(width: 380, child: LessonDetail(row: state.selected)),
            ],
          ),
        ),
      ],
    );
  }
}

// Figma: „Poruke · mobile lista“ i „mobile detalj“. Ili lista, ili detalj preko celog prostora.
class _NarrowView extends StatefulWidget {
  const _NarrowView({required this.state});

  final LessonQueueLoaded state;

  @override
  State<_NarrowView> createState() => _NarrowViewState();
}

class _NarrowViewState extends State<_NarrowView> {
  // Čas čiji je detalj otvoren. Ovo zna samo uzak raspored, pa nije u Blocu. Kad se prozor raširi, nestaje.
  LessonId? _openId;

  // Bloc je pomerio izbor sa otvorenog časa, na primer posle Potvrdi čas više nije u tabu.
  // Tada se vraćamo na listu, gde se vidi šta se promenilo.
  @override
  void didUpdateWidget(_NarrowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.selectedId != _openId) _openId = null;
  }

  // Izbor i dalje drži Bloc. Ovde se samo pamti da je detalj otvoren.
  void _open(LessonId id) {
    context.read<LessonQueueBloc>().add(RowSelected(id));
    setState(() => _openId = id);
  }

  void _close() => setState(() => _openId = null);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selected = state.selected;
    if (selected == null || selected.lesson.id != _openId) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.px16,
        children: [
          QueueTabs(state: state),
          Expanded(
            child: QueueList(state: state, onOpen: _open),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px16,
      children: [
        Row(
          children: [
            TextButton.icon(onPressed: _close, icon: const Icon(Icons.arrow_back), label: const Text('Nazad')),
            const Spacer(),
            LessonStatusBadge(status: selected.lesson.status),
          ],
        ),
        Expanded(child: LessonDetail(row: selected)),
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
      title: 'Časovi nisu učitani.',
      text: message,
      action: FilledButton(
        onPressed: () => context.read<LessonQueueBloc>().add(QueueRetried()),
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
      icon: Icons.event_available_outlined,
      title: 'Još nema zahteva za časove.',
      text: 'Kad učenik zatraži termin iz vašeg oglasa, zahtev će se pojaviti ovde.',
    );
  }
}
