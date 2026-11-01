import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../text/domain_errors.dart';

// Dugme „Odbij uz razlog“ zove ovo, a kasnije i taster O. Dijalog samo skuplja razlog,
// a odluku šalje kao događaj Blocu, isto kao dugme Verifikuj.
Future<void> rejectSelected(BuildContext context) async {
  // Bloc uzimamo pre await-a. Posle zatvaranja dijaloga context možda više nije na ekranu.
  final bloc = context.read<VerificationQueueBloc>();
  final state = bloc.state;
  if (state is! VerificationQueueLoaded) return;
  final profile = state.selected;
  if (profile == null) return;

  final reason = await showDialog<String>(
    context: context,
    builder: (context) => _RejectDialog(name: profile.fullName),
  );
  // null znači da je administrator kliknuo Odustani ili zatvorio dijalog.
  if (reason == null) return;
  bloc.add(RejectProfessorPressed(reason));
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.name});

  final String name;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    // Isto pravilo proverava i use case. Ovde je samo da se greška vidi dok se kuca, a ne tek posle klika.
    final parsed = RejectionReason.parse(text);
    // Prazno polje još nije greška, inače bi dijalog bio crven čim se otvori.
    String? error;
    if (parsed is Failure<RejectionReason> && text.isNotEmpty) {
      error = parsed.error.message;
    }
    return AlertDialog(
      title: Text('Odbij: ${widget.name}'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          // Svako slovo ponovo crta dijalog, pa se greška i dugme menjaju dok se kuca.
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Razlog',
            hintText: 'Napišite profesoru šta treba da ispravi.',
            errorText: error,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(
          style: AppButtonStyles.destructive,
          // null isključuje dugme dok razlog nije dovoljno dug.
          onPressed: parsed is Success<RejectionReason> ? () => Navigator.of(context).pop(text) : null,
          child: const Text('Odbij'),
        ),
      ],
    );
  }
}
