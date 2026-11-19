import 'package:backoffice/text/failures.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  test('every repository failure has its own text', () {
    final texts = RepositoryFailure.values.map((failure) => failure.message).toSet();

    expect(texts, hasLength(RepositoryFailure.values.length));
    expect(RepositoryFailure.unreachable.message, 'Nema veze sa serverom. Proveri da li server radi.');
  });

  test('a notice shows the rule text or the failure text', () {
    expect(const ActionRejected(LessonChanged()).message, 'Čas je u međuvremenu promenjen. Lista je osvežena.');
    expect(const ActionFailed(RepositoryFailure.serverError).message, RepositoryFailure.serverError.message);
  });
}
