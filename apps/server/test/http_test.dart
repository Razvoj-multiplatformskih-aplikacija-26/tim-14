import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:http/http.dart' as http;
import 'package:relic/relic.dart';
import 'package:server/src/http.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart' show RepositoryException;

late RelicServer server;
late Uri base;

const jsonHeaders = {'Content-Type': 'application/json'};

String codeOf(http.Response response) => (jsonDecode(response.body) as Map<String, Object?>)['code']! as String;

void main() {
  setUpAll(() async {
    final router = RelicRouter()
      ..post('/echo', (request) async => json(200, await readObject(request)))
      ..get('/boom', (request) => throw StateError('a bug in a handler'))
      ..get('/missing', (request) => throw const RecordNotFound('No professor nobody'))
      ..get('/db-down', (request) => throw const RepositoryException('The database is unavailable', cause: 'refused'));
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(const Pipeline().addMiddleware(handleErrors()).addHandler(router.asHandler));
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() => server.close());

  Future<http.Response> echo(String body, {Map<String, String> headers = jsonHeaders}) => http.post(
    base.replace(path: '/echo'),
    headers: headers,
    body: body,
  );

  test('a JSON object is read', () async {
    final response = await echo('{"login": "ucenik1"}');

    expect(response.statusCode, 200);
    expect(response.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(response.body), {'login': 'ucenik1'});
  });

  test('a body that is not JSON is 415', () async {
    final response = await echo('login=ucenik1', headers: {'Content-Type': 'application/x-www-form-urlencoded'});

    expect(response.statusCode, 415);
    expect(codeOf(response), ErrorCodes.unsupportedMediaType);
  });

  test('broken JSON is 400', () async {
    final response = await echo('{"login": ');

    expect(response.statusCode, 400);
    expect(codeOf(response), ErrorCodes.badRequest);
  });

  test('JSON that is not an object is 400', () async {
    final response = await echo('["ucenik1"]');

    expect(response.statusCode, 400);
    expect(codeOf(response), ErrorCodes.badRequest);
  });

  test('a body over the limit is 413', () async {
    final response = await echo(jsonEncode({'message': 'x' * (maxBodyBytes + 1)}));

    expect(response.statusCode, 413);
    expect(codeOf(response), ErrorCodes.payloadTooLarge);
  });

  test('an unexpected exception is a 500 that leaks nothing', () async {
    final response = await http.get(base.replace(path: '/boom'));

    expect(response.statusCode, 500);
    expect(response.headers['content-type'], startsWith(ProblemDto.mediaType));
    expect(codeOf(response), ErrorCodes.serverError);
    expect(response.body, isNot(contains('a bug in a handler')));
  });

  test('an unreachable database is a 503 that leaks nothing', () async {
    final response = await http.get(base.replace(path: '/db-down'));

    expect(response.statusCode, 503);
    expect(codeOf(response), ErrorCodes.serviceUnavailable);
    expect(response.body, isNot(contains('refused')));
  });

  test('a record that does not exist is a 404', () async {
    final response = await http.get(base.replace(path: '/missing'));

    expect(response.statusCode, 404);
    expect(codeOf(response), ErrorCodes.notFound);
  });
}
