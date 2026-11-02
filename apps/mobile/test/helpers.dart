import 'package:mobile/data/demo_data.dart';
import 'package:mobile/data/fail_switch.dart';
import 'package:mobile/data/fake_professor_repository.dart';

// Isti demo profesori kao u main.dart.
FakeProfessorRepository demoProfessorRepository(FailSwitch failSwitch) => FakeProfessorRepository(
  profiles: demoProfessors,
  listings: demoListings,
  slots: demoSlots(DateTime.now()),
  failSwitch: failSwitch,
);
