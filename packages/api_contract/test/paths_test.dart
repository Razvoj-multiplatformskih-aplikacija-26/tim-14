import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  test('the client fills in an id, the server registers the same path with :id', () {
    expect(ApiPaths.withdrawal('l-1'), '/lessons/l-1/withdrawal');
    expect(ApiPaths.withdrawal(':id'), '/lessons/:id/withdrawal');
    expect(ApiPaths.noShow('l-1'), '/lessons/l-1/no-show');
    expect(ApiPaths.takenSlotsOf('milica'), '/professors/milica/taken-slots');
    expect(ApiPaths.verificationRejection('jovan'), '/verifications/jovan/rejection');
    expect(ApiPaths.linkedIn('jovan'), '/verifications/jovan/linkedin');
  });

  test('every path of the plan exists', () {
    expect(
      [
        ApiPaths.health,
        ApiPaths.sessions,
        ApiPaths.currentSession,
        ApiPaths.professors,
        ApiPaths.professor('p'),
        ApiPaths.listingsOf('p'),
        ApiPaths.slotsOf('p'),
        ApiPaths.lessons,
        ApiPaths.lesson('l'),
        ApiPaths.cancellation('l'),
        ApiPaths.confirmation('l'),
        ApiPaths.rejection('l'),
        ApiPaths.held('l'),
        ApiPaths.verifications,
        ApiPaths.approval('p'),
      ],
      [
        '/health',
        '/sessions',
        '/sessions/current',
        '/professors',
        '/professors/p',
        '/professors/p/listings',
        '/professors/p/slots',
        '/lessons',
        '/lessons/l',
        '/lessons/l/cancellation',
        '/lessons/l/confirmation',
        '/lessons/l/rejection',
        '/lessons/l/held',
        '/verifications',
        '/verifications/p/approval',
      ],
    );
  });
}
