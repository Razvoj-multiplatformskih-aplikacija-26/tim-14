import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RequestMessage', () {
    test('is required', () {
      expect(RequestMessage.parse('').errorOrNull, const InvalidRequestMessage(0));
      expect(RequestMessage.parse('   ').errorOrNull, const InvalidRequestMessage(0));
    });

    test('trims the text', () {
      expect(RequestMessage.parse('  Integrali  ').valueOrNull!.text, 'Integrali');
    });

    test('accepts 1 to 300 characters', () {
      expect(RequestMessage.parse('a').isSuccess, isTrue);
      expect(RequestMessage.parse('a' * 300).isSuccess, isTrue);
    });

    test('refuses 301 characters', () {
      expect(RequestMessage.parse('a' * 301).errorOrNull, const InvalidRequestMessage(301));
    });

    test('counts an emoji as one character', () {
      expect(RequestMessage.parse('${'a' * 299}👩‍👩‍👧').isSuccess, isTrue);
      expect(RequestMessage.parse('${'a' * 300}👍').errorOrNull, const InvalidRequestMessage(301));
    });
  });

  group('LessonNote', () {
    test('may be empty', () {
      expect(LessonNote.parse('  ').valueOrNull!.isEmpty, isTrue);
    });

    test('accepts up to 500 characters', () {
      expect(LessonNote.parse('a' * 500).isSuccess, isTrue);
      expect(LessonNote.parse('a' * 501).errorOrNull, const NoteTooLong(501));
    });
  });

  group('ReviewText', () {
    test('may be empty', () {
      expect(ReviewText.parse('').valueOrNull!.isEmpty, isTrue);
    });

    test('accepts up to 1000 characters', () {
      expect(ReviewText.parse('a' * 1000).isSuccess, isTrue);
      expect(ReviewText.parse('a' * 1001).errorOrNull, const ReviewTextTooLong(1001));
    });
  });

  group('Rating', () {
    test('accepts 1 to 5 stars', () {
      for (var stars = Rating.min; stars <= Rating.max; stars++) {
        expect(Rating.parse(stars).valueOrNull!.stars, stars);
      }
    });

    test('refuses anything outside 1 to 5', () {
      expect(Rating.parse(0).errorOrNull, const InvalidRating(0));
      expect(Rating.parse(6).errorOrNull, const InvalidRating(6));
    });
  });

  group('Price', () {
    test('is a positive number of dinars', () {
      expect(Price.parse(1).isSuccess, isTrue);
      expect(Price.parse(2500).valueOrNull!.dinars, 2500);
    });

    test('refuses zero and negative prices', () {
      expect(Price.parse(0).errorOrNull, const InvalidPrice(0));
      expect(Price.parse(-500).errorOrNull, const InvalidPrice(-500));
    });
  });

  group('LessonDuration', () {
    test('is 45, 60 or 90 minutes', () {
      expect([for (final duration in LessonDuration.values) duration.duration.inMinutes], [45, 60, 90]);
    });
  });

  group('LinkedInUrl', () {
    test('accepts a public profile link', () {
      for (final input in [
        'https://www.linkedin.com/in/jelena-petrovic',
        'https://linkedin.com/in/jelena-petrovic/',
        '  https://www.linkedin.com/in/jelena-petrovic  ',
      ]) {
        expect(LinkedInUrl.parse(input).isSuccess, isTrue, reason: input);
      }
    });

    test('refuses anything else', () {
      for (final input in [
        '',
        'not a link',
        'linkedin.com/in/jelena-petrovic',
        'http://www.linkedin.com/in/jelena-petrovic',
        'https://example.com/in/jelena-petrovic',
        'https://www.linkedin.com/company/raf',
        'https://www.linkedin.com/in/',
        'https://www.linkedin.com/in/jelena-petrovic/details',
      ]) {
        expect(LinkedInUrl.parse(input).errorOrNull, isA<InvalidLinkedInUrl>(), reason: input);
      }
    });
  });
}
