import 'package:backoffice/text/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes the weekday, day, month and time in Serbian', () {
    expect(formatDateTime(DateTime(2026, 11, 5, 17)), 'čet 5. nov u 17:00');
  });

  test('pads the minutes but not the hour', () {
    expect(formatDateTime(DateTime(2026, 11, 2, 9, 5)), 'pon 2. nov u 9:05');
  });

  // Lesson čuva vreme u UTC-u, a ekran mora da pokaže lokalno.
  test('shows a UTC time in local time', () {
    final local = DateTime(2026, 11, 5, 17);

    expect(formatDateTime(local.toUtc()), 'čet 5. nov u 17:00');
    expect(formatShortDateTime(local.toUtc()), '5. nov 17:00');
  });

  test('the short form drops the weekday', () {
    expect(formatShortDateTime(DateTime(2026, 10, 30, 10)), '30. okt 10:00');
  });

  test('a year range without an end says danas', () {
    expect(formatYears(2014, 2019), '2014 – 2019');
    expect(formatYears(2019, null), '2019 – danas');
  });
}
