import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart' show DomainError, Result, Success;
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart' show RepositoryException;

final _problemMimeType = MimeType.parse(ProblemDto.mediaType);

Response json(int status, Object? body) =>
    Response(status, body: Body.fromString(jsonEncode(body), mimeType: MimeType.json));

Response problemResponse(ProblemDto problem) =>
    Response(problem.status, body: Body.fromString(jsonEncode(problem.toJson()), mimeType: _problemMimeType));

/// A refusal by a domain rule, as a problem response. In Spring terms: what an `@ExceptionHandler` makes of an
/// exception, except that here the rule returns its refusal as a value instead of throwing it.
/// The code and the rule's numbers come from `api_mapping`, the same mapping the clients read them back with.
Response problem(DomainError error) => problemResponse(error.toProblem());

/// What a handler answers with the result of a use case: the value as JSON, or the refusal as a problem.
/// [toJson] turns the value into JSON; [status] is for a success other than 200, such as 201 for a create.
Response respond<T>(Result<T> result, Object? Function(T value) toJson, {int status = 200}) {
  if (result is Success<T>) {
    final value = result.value;
    return json(status, toJson(value));
  }
  return problem(result.errorOrNull!);
}

Response badRequest(String title) =>
    problemResponse(ProblemDto(status: 400, code: ErrorCodes.badRequest, title: title));

const maxBodyBytes = 16 * 1024;

final class UnsupportedMediaType implements Exception {
  const UnsupportedMediaType();
}

/// A repository was asked for one record by id and there is none. [handleErrors] answers 404.
/// In Spring terms: `EntityNotFoundException`, mapped to 404 by a `@ControllerAdvice`.
final class RecordNotFound implements Exception {
  const RecordNotFound(this.message);

  final String message;

  @override
  String toString() => 'RecordNotFound($message)';
}

/// Reads the request body as one JSON object. Throws, and [handleErrors] turns the throw into a problem:
/// not JSON → 415, too big → 413, broken JSON or not an object → 400.
Future<Map<String, Object?>> readObject(Request request) async {
  if (request.mimeType != MimeType.json) throw const UnsupportedMediaType();
  return switch (jsonDecode(await request.readAsString(maxLength: maxBodyBytes))) {
    final Map<String, Object?> object => object,
    _ => throw const FormatException('Expected a JSON object'),
  };
}

Middleware handleErrors() =>
    (Handler next) => (Request request) async {
      try {
        return await next(request);
      } on FormatException catch (error) {
        return badRequest(error.message);
      } on UnsupportedMediaType {
        return problemResponse(unsupportedMediaType);
      } on MaxBodySizeExceeded {
        return problemResponse(payloadTooLarge);
      } on RecordNotFound {
        return problemResponse(notFound);
      } on RepositoryException catch (error) {
        stderr.writeln('${request.method} ${request.url.path}: ${error.message}: ${error.cause}');
        return problemResponse(serviceUnavailable);
      } catch (error, stackTrace) {
        stderr.writeln('${request.method} ${request.url.path}: $error\n$stackTrace');
        return problemResponse(serverError);
      }
    };

const unsupportedMediaType = ProblemDto(
  status: 415,
  code: ErrorCodes.unsupportedMediaType,
  title: 'Expected application/json',
);

const payloadTooLarge = ProblemDto(status: 413, code: ErrorCodes.payloadTooLarge, title: 'Request body too large');

/// 401 for a route that needs a caller and got none.
const signInRequired = ProblemDto(status: 401, code: ErrorCodes.signInRequired, title: 'Sign in first');

const notFound = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found');

const serverError = ProblemDto(status: 500, code: ErrorCodes.serverError, title: 'Server error');

const serviceUnavailable = ProblemDto(
  status: 503,
  code: ErrorCodes.serviceUnavailable,
  title: 'Service temporarily unavailable',
);
