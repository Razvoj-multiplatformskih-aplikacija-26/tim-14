import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/demo_data.dart';

void main() {
  test('demo slots of one professor do not overlap', () {
    final slots = demoSlots(DateTime.now());

    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final a = slots[i];
        final b = slots[j];
        if (a.professorId != b.professorId) continue;
        expect(a.overlaps(b), isFalse, reason: '${a.id.value} i ${b.id.value} se preklapaju');
      }
    }
  });
}
