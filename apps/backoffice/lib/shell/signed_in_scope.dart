import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:use_cases/use_cases.dart';

import '../dependencies.dart';

// Blocovi jednog prijavljenog korisnika. Use case-ovi dobijaju baš tog korisnika, pa server i domen
// proveravaju njega, a ne nekog unapred zadatog.
// Kad se korisnik odjavi, ruter ovaj vidžet skloni, BlocProvider zatvori svoj Bloc, i sledeći korisnik ne vidi tuđ red.
class SignedInScope extends StatelessWidget {
  const SignedInScope({super.key, required this.user, required this.child});

  final User user;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dependencies = context.read<BackofficeDependencies>();
    const clock = SystemClock();
    // Svaka uloga dobija samo Bloc za svoj deo aplikacije.
    return switch (user.role) {
      Role.professor => BlocProvider(
        create: (context) {
          final lessons = dependencies.lessons;
          return LessonQueueBloc(
            GetLessonQueue(lessons, user),
            ConfirmLesson(lessons, clock, user),
            RejectLesson(lessons, clock, user),
            RecordHeld(lessons, clock, user),
            RecordNoShow(lessons, clock, user),
          )..add(QueueRequested());
        },
        child: child,
      ),
      Role.admin => BlocProvider(
        create: (context) {
          final verifications = dependencies.verifications;
          return VerificationQueueBloc(
            GetVerificationQueue(verifications),
            VerifyProfessor(verifications, clock, user),
            RejectProfessor(verifications, clock, user),
          )..add(VerificationRequested());
        },
        child: child,
      ),
      // SessionBloc ne pušta učenika u backoffice, pa ova grana nikad ne crta deo aplikacije.
      Role.student => child,
    };
  }
}
