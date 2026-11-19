/// The `code` values of `ProblemDto`s. Clients switch on these, never on the HTTP status.
abstract final class ErrorCodes {
  static const notFound = 'not-found';
  static const badRequest = 'bad-request';
  static const unsupportedMediaType = 'unsupported-media-type';
  static const payloadTooLarge = 'payload-too-large';
  static const serverError = 'server-error';
  static const serviceUnavailable = 'service-unavailable';
}
