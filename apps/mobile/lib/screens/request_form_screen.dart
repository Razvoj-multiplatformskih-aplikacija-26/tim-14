import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../text/catalog.dart';
import '../text/dates.dart';
import '../text/domain_errors.dart';

class RequestFormScreen extends StatelessWidget {
  const RequestFormScreen({super.key, required this.professorId, required this.slotId});

  final UserId professorId;
  final SlotId slotId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RequestFormBloc(context.read<GetProfessorPage>(), context.read<RequestLesson>(), professorId, slotId)
            ..add(RequestFormStarted()),
      child: const _RequestFormView(),
    );
  }
}

class _RequestFormView extends StatelessWidget {
  const _RequestFormView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zahtev za čas')),
      body: BlocConsumer<RequestFormBloc, RequestFormState>(
        // Kad je zahtev poslat, osvežimo Moje časove da se novi zahtev vidi kao "Na čekanju".
        listenWhen: (previous, current) => current is RequestFormSent,
        listener: (context, state) => context.read<MyLessonsBloc>().add(MyLessonsRequested()),
        builder: (context, state) {
          switch (state) {
            case RequestFormLoading():
              return const Center(child: CircularProgressIndicator());
            case RequestFormLoadFailure():
              return _Message(
                icon: Icons.wifi_off,
                text: 'Termin trenutno ne može da se učita.',
                buttonText: 'Pokušaj ponovo',
                onPressed: () => context.read<RequestFormBloc>().add(RequestFormStarted()),
              );
            case RequestFormSlotGone():
              return _Message(
                icon: Icons.event_busy,
                text: 'Ovaj termin više nije slobodan.',
                buttonText: 'Nazad na profil',
                onPressed: () => context.pop(),
              );
            case RequestFormReady():
              return _Form(state: state);
            case RequestFormSent():
              return _Message(
                icon: Icons.check_circle_outline,
                text: 'Zahtev je poslat. Profesor će ga potvrditi ili odbiti.',
                buttonText: 'Nazad na moje časove',
                onPressed: () => context.go('/casovi'),
              );
          }
        },
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final RequestFormReady state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mutedColor = scheme.onSurfaceVariant;
    final bloc = context.read<RequestFormBloc>();
    // Broji se isto kao u domenu, bez razmaka na krajevima.
    final length = state.message.trim().characters.length;
    final isTooLong = length > RequestMessage.maxLength;

    // Greška pri slanju: pravilo iz domena ili mreža.
    String? errorText;
    if (state.submitError != null) {
      errorText = state.submitError!.message;
    } else if (state.networkError != null) {
      errorText = 'Zahtev nije poslat, proveri mrežu i pokušaj ponovo.';
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.px16),
      children: [
        if (errorText != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.px12),
            decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(errorText, style: AppTextStyles.bodySm.copyWith(color: scheme.onErrorContainer)),
          ),
          const SizedBox(height: AppSpacing.px16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.px16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(name: state.profile.fullName),
                    const SizedBox(width: AppSpacing.px12),
                    Expanded(child: Text(state.profile.fullName, style: AppTextStyles.bodyBaseMedium)),
                  ],
                ),
                const SizedBox(height: AppSpacing.px12),
                Text(state.listing.description, style: AppTextStyles.bodySm),
                const SizedBox(height: AppSpacing.px2),
                Text(
                  '${state.listing.subject.label} · ${state.listing.level.label} · ${state.listing.city.label}',
                  style: AppTextStyles.bodySm.copyWith(color: mutedColor),
                ),
                const SizedBox(height: AppSpacing.px12),
                Text(formatLessonTime(state.slot.start), style: AppTextStyles.bodySmMedium),
                const SizedBox(height: AppSpacing.px2),
                Text(
                  '${formatPrice(state.listing.price)} / ${state.listing.duration.minutes} min',
                  style: AppTextStyles.bodySm.copyWith(color: mutedColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.px24),
        TextField(
          minLines: 4,
          maxLines: 8,
          enabled: !state.isSending,
          onChanged: (text) => bloc.add(MessageChanged(text)),
          decoration: InputDecoration(
            labelText: 'Poruka profesoru',
            hintText: 'Napiši šta ti je potrebno, npr. pomoć oko integrala.',
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            errorText: state.messageError?.message,
            // Brojač postaje crven kad se pređe 300 znakova.
            counter: Text(
              '$length/${RequestMessage.maxLength}',
              style: AppTextStyles.captionXs.copyWith(color: isTooLong ? scheme.error : mutedColor),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.px16),
        FilledButton(
          // Dugme je sivo dok poruka nije dobra ili dok se šalje.
          onPressed: state.canSend ? () => bloc.add(RequestSubmitted()) : null,
          child: state.isSending
              ? const SizedBox.square(dimension: AppSpacing.px16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Pošalji zahtev'),
        ),
      ],
    );
  }
}

// Poruka na sredini ekrana sa ikonom i jednim dugmetom.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.buttonText, required this.onPressed});

  final IconData icon;
  final String text;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.px24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.px48),
            const SizedBox(height: AppSpacing.px16),
            Text(text, style: AppTextStyles.bodyBaseMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.px16),
            FilledButton(onPressed: onPressed, child: Text(buttonText)),
          ],
        ),
      ),
    );
  }
}
