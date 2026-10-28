import '../access_policy.dart';
import '../errors.dart';
import '../result.dart';
import '../user.dart';
import 'slot.dart';

bool isOnHalfHour(DateTime instant) {
  final utc = instant.toUtc();
  return utc.minute % 30 == 0 && utc.second == 0 && utc.millisecond == 0 && utc.microsecond == 0;
}

Result<Slot> addSlot(Slot candidate, {required List<Slot> existing, required User by, required DateTime now}) {
  if (!AccessPolicy.canManageSlots(by, professorId: candidate.professorId)) return const Failure(NotAllowed());
  if (!isOnHalfHour(candidate.start)) return const Failure(SlotNotOnHalfHour());
  if (!candidate.start.isAfter(now.toUtc())) return const Failure(SlotInPast());
  final overlaps = existing.any((slot) => slot.professorId == candidate.professorId && slot.overlaps(candidate));
  if (overlaps) return const Failure(SlotOverlaps());
  return Success(candidate);
}
