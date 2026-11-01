const _days = ['ponedeljak', 'utorak', 'sreda', 'četvrtak', 'petak', 'subota', 'nedelja'];

const _months = [
  'januara',
  'februara',
  'marta',
  'aprila',
  'maja',
  'juna',
  'jula',
  'avgusta',
  'septembra',
  'oktobra',
  'novembra',
  'decembra',
];

// Npr. "četvrtak, 5. novembra, 17:00". Vremena u domenu su UTC, pa ih prvo prebacimo u lokalno.
String formatLessonTime(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_days[local.weekday - 1]}, ${local.day}. ${_months[local.month - 1]}, $hour:$minute';
}
