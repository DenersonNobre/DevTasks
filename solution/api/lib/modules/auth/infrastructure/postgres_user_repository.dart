import 'package:postgres/postgres.dart';

import '../../../core/db/sql_executor.dart';
import '../ports.dart';

/// Adaptador PostgreSQL para persistência de usuários e leitura de credenciais.
///
/// Implementa [IUserRepository] e [ICredentialRepository] garantindo:
/// - Unicidade de e-mail tratada na persistência (INV-08, código 23505);
/// - ISP: handlers consomem apenas os métodos da interface necessária;
/// - DIP: sem dependência do framework web shelf; apenas [ISqlExecutor].
class PostgresUserRepository implements IUserRepository, ICredentialRepository {
  const PostgresUserRepository(this._sql);

  final ISqlExecutor _sql;

  static const String _uniqueViolationCode = '23505';

  @override
  Future<bool> existsByEmail(String normalizedEmail) async {
    final rows = await _sql.query(
      'SELECT 1 FROM devtasks_user WHERE email = @email LIMIT 1',
      parameters: {'email': normalizedEmail},
    );
    return rows.isNotEmpty;
  }

  @override
  Future<CreateUserOutcome> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    try {
      final rows = await _sql.query(
        'INSERT INTO devtasks_user (name, email, password_hash) '
        'VALUES (@name, @email, @passwordHash) '
        'RETURNING id, name, email',
        parameters: {
          'name': name,
          'email': email,
          'passwordHash': passwordHash,
        },
      );

      final row = rows.first;
      return UserCreated(
        RegisteredUser(
          id: row['id'].toString(),
          name: row['name']! as String,
          email: row['email']! as String,
          emailVerified: false,
        ),
      );
    } on ServerException catch (e) {
      if (e.code == _uniqueViolationCode) {
        return const EmailTaken();
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile?> findById(String userId) async {
    final rows = await _sql.query(
      'SELECT id, name, email FROM devtasks_user WHERE id = @id LIMIT 1',
      parameters: {'id': userId},
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return UserProfile(
      userId: row['id'].toString(),
      name: row['name']! as String,
      email: row['email']! as String,
    );
  }

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async {
    final rows = await _sql.query(
      'SELECT id, email, password_hash FROM devtasks_user WHERE email = @email LIMIT 1',
      parameters: {'email': normalizedEmail},
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return CredentialRecord(
      id: row['id'].toString(),
      email: row['email']! as String,
      passwordHash: row['password_hash']! as String,
    );
  }

  @override
  Future<String?> findEmailById(String userId) async {
    final rows = await _sql.query(
      'SELECT email FROM devtasks_user WHERE id = @id LIMIT 1',
      parameters: {'id': userId},
    );
    if (rows.isEmpty) {
      return null;
    }

    return rows.first['email'] as String?;
  }
}

