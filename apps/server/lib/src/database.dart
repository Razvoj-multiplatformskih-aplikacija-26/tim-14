import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show PgException, Pool, ServerException, Session, Severity, TxSession;
import 'package:use_cases/use_cases.dart';

const uniqueViolation = '23505';

/// The partial unique index from the migration: at most one confirmed lesson per slot.
const oneConfirmedPerSlot = 'lessons_one_confirmed_per_slot';

/// The server's handle on Postgres. In Spring terms: the pool is HikariCP, [run] is JdbcTemplate,
/// [transaction] is @Transactional, and [translateDatabaseErrors] is the SQLExceptionTranslator.
final class Database {
  Database._(this._pool);

  final Pool<void> _pool;

  /// Opens the pool and checks that Postgres answers. A wrong URL or a stopped database fails here, at
  /// startup, and not on the first request.
  ///
  /// The pool of `package:postgres` holds 1 connection unless told otherwise, so every request would wait
  /// for the one before it. [maxConnections] (10, HikariCP's default) is used unless the URL sets
  /// `max_connection_count` itself.
  static Future<Database> open(String url, {int maxConnections = 10}) async {
    final database = Database._(Pool.withUrl(_withPoolSize(url, maxConnections)));
    try {
      await database.run((db) => db.execute('SELECT 1'));
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  /// Statements outside a transaction, on any free connection. For reads and single statements.
  Future<T> run<T>(Future<T> Function(Session db) work) => translateDatabaseErrors(() => _pool.run(work));

  /// Statements that commit or roll back together. A [Success] commits. A [Failure] or a throw rolls back.
  ///
  /// `runTx` alone commits whenever [work] returns, so a [Failure] needs the explicit rollback.
  Future<Result<T>> transaction<T>(Future<Result<T>> Function(TxSession tx) work) => translateDatabaseErrors(
    () => _pool.runTx((tx) async {
      final result = await work(tx);
      if (result is Failure<T>) await tx.rollback();
      return result;
    }),
    onSlotTaken: () => Failure(const SlotTaken()),
  );

  Future<void> close() => _pool.close();
}

/// The one place that reads what Postgres threw.
///
/// - 23505 on [oneConfirmedPerSlot]: the database refused a second confirmed lesson for one slot. The caller
///   gets [onSlotTaken]'s value. Only writes pass it.
/// - ERROR from Postgres means one statement failed, which is a bug in our SQL. It is rethrown, and
///   `handleErrors` logs it and answers 500.
/// - FATAL means the connection is dead (wrong password, database restarted). That, a dropped connection,
///   a refused one or a timeout becomes a [RepositoryException], which `handleErrors` answers with 503.
Future<T> translateDatabaseErrors<T>(Future<T> Function() work, {T Function()? onSlotTaken}) async {
  try {
    return await work();
  } catch (error) {
    switch (error) {
      case ServerException(code: uniqueViolation, constraintName: oneConfirmedPerSlot) when onSlotTaken != null:
        return onSlotTaken();
      case ServerException(severity: Severity.error):
        rethrow;
      case PgException() || SocketException() || TimeoutException():
        throw RepositoryException('The database is unavailable', cause: error);
      default:
        rethrow;
    }
  }
}

String _withPoolSize(String url, int maxConnections) {
  final uri = Uri.parse(url);
  if (uri.queryParameters.containsKey('max_connection_count')) return url;
  return uri.replace(queryParameters: {...uri.queryParameters, 'max_connection_count': '$maxConnections'}).toString();
}
