import '../../../core/db/sql_executor.dart';
import '../ports.dart';

/// Adaptador PostgreSQL para persistência e revogação de sessões.
///
/// Implementa [SessionRepository] garantindo:
/// - Persistência apenas do hash SHA-256 do token (INV-SEC-17);
/// - Revogação idempotente via marcação temporal `revoked_at`;
/// - DIP: sem acoplamento com HTTP ou framework web.
class PostgresSessionRepository implements SessionRepository {
  const PostgresSessionRepository(this._sql);

  final SqlExecutor _sql;

  @override
  Future<void> save(SessionRecord session) async {
    await _sql.execute(
      'INSERT INTO devtasks_session (user_id, token_hash, expires_at, created_at, revoked_at) '
      'VALUES (@userId::uuid, @tokenHash, @expiresAt, @createdAt, @revokedAt)',
      parameters: {
        'userId': session.userId,
        'tokenHash': session.tokenHash,
        'expiresAt': session.expiresAt,
        'createdAt': session.createdAt,
        'revokedAt': session.revokedAt,
      },
    );
  }

  @override
  Future<SessionRecord?> findByTokenHash(String tokenHash) async {
    final rows = await _sql.query(
      'SELECT user_id, token_hash, expires_at, created_at, revoked_at '
      'FROM devtasks_session '
      'WHERE token_hash = @tokenHash '
      'LIMIT 1',
      parameters: {'tokenHash': tokenHash},
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return SessionRecord(
      userId: row['user_id'].toString(),
      tokenHash: row['token_hash']! as String,
      expiresAt: (row['expires_at']! as DateTime).toUtc(),
      createdAt: (row['created_at']! as DateTime).toUtc(),
      revokedAt: (row['revoked_at'] as DateTime?)?.toUtc(),
    );
  }

  @override
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt) async {
    await _sql.execute(
      'UPDATE devtasks_session '
      'SET revoked_at = @revokedAt '
      'WHERE token_hash = @tokenHash AND revoked_at IS NULL',
      parameters: {
        'tokenHash': tokenHash,
        'revokedAt': revokedAt,
      },
    );
  }
}
