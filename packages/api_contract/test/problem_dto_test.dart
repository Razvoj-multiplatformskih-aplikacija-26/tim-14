import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  test('a problem with every field survives a round trip', () {
    const problem = ProblemDto(
      status: 409,
      code: 'invalid-transition',
      title: 'Lesson is not pending',
      value: 3,
      min: 1,
      max: 5,
      minutes: 1440,
      from: {'type': 'confirmed', 'at': '2026-11-20T10:00:00.000Z'},
      to: {'type': 'withdrawn'},
    );

    expect(ProblemDto.fromJson(problem.toJson()).toJson(), problem.toJson());
  });

  test('absent fields stay off the wire', () {
    const problem = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');

    expect(problem.toJson(), {
      'type': 'tag:raf.rs,2026:casovi/problem/not-found',
      'title': 'No such route',
      'status': 404,
      'code': 'not-found',
    });
    expect(ProblemDto.fromJson(problem.toJson()).toJson(), problem.toJson());
  });

  test('a problem without a title still reads', () {
    final problem = ProblemDto.fromJson({'status': 500, 'code': ErrorCodes.serverError});

    expect(problem.title, '');
    expect(problem.code, ErrorCodes.serverError);
  });

  test('a problem without a code is rejected', () {
    expect(() => ProblemDto.fromJson({'status': 500}), throwsFormatException);
  });
}
