// Projekat nema intl, pa su kratki nazivi dana i meseci napisani ovde. DateTime.weekday ide od 1 (ponedeljak).
const _weekdays = ['pon', 'uto', 'sre', 'čet', 'pet', 'sub', 'ned'];
const _months = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];

// „čet 5. nov u 17:00“. Domen čuva vreme u UTC-u, pa se pre ispisa prebacuje u lokalno.
String formatDateTime(DateTime at) {
  final local = at.toLocal();
  return '${_weekdays[local.weekday - 1]} ${local.day}. ${_months[local.month - 1]} u ${_time(local)}';
}

// „5. nov 17:00“, za kolone tabele gde nema mesta za dan u nedelji.
String formatShortDateTime(DateTime at) {
  final local = at.toLocal();
  return '${local.day}. ${_months[local.month - 1]} ${_time(local)}';
}

String _time(DateTime local) => '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
