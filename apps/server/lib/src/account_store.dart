import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Sql;

import 'database.dart';

/// A user who can sign in, with the Argon2id hash of their password. The password itself is never stored.
final class Account {
  const Account({required this.user, required this.passwordHash});

  final User user;
  final String passwordHash;
}

/// Where the login looks accounts up. A port, so the login can be tested without a database.
abstract interface class AccountStore {
  /// The account with this login, or null if there is none.
  Future<Account?> account(String login);
}

/// Accounts in `users`. A user without a login or without a password hash cannot sign in.
final class PostgresAccountStore implements AccountStore {
  const PostgresAccountStore(this._database);

  final Database _database;

  @override
  Future<Account?> account(String login) => _database.run((db) async {
    final rows = await db.execute(
      Sql.named('SELECT id, name, role, password_hash FROM users WHERE login = @login AND password_hash IS NOT NULL'),
      parameters: {'login': login},
    );
    if (rows.isEmpty) {
      return null;
    }
    final column = rows.single.toColumnMap();
    return Account(
      user: User(
        id: UserId(column['id'] as String),
        name: column['name'] as String,
        role: Role.values.byName(column['role'] as String),
      ),
      passwordHash: column['password_hash'] as String,
    );
  });
}
