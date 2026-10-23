import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'serverpod_session_service.dart';

/// Adaptador Serverpod para [SessionRepository] que interage com a tabela `devtasks_session`.
class ServerpodSessionRepository implements SessionRepository {
  const ServerpodSessionRepository(this._session);

  final Session _session;

  @override
  Future<void> save(SessionRecord session) async {
    final entity = DevtasksSession(
      userId: session.userId,
      tokenHash: session.tokenHash,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      revokedAt: session.revokedAt,
    );
    await DevtasksSession.db.insertRow(_session, entity);
  }

  @override
  Future<SessionRecord?> findByTokenHash(String tokenHash) async {
    final row = await DevtasksSession.db.findFirstRow(
      _session,
      where: (t) => t.tokenHash.equals(tokenHash),
    );
    if (row == null) {
      return null;
    }
    return SessionRecord(
      userId: row.userId,
      tokenHash: row.tokenHash,
      createdAt: row.createdAt,
      expiresAt: row.expiresAt,
      revokedAt: row.revokedAt,
    );
  }

  @override
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt) async {
    final existing = await DevtasksSession.db.findFirstRow(
      _session,
      where: (t) => t.tokenHash.equals(tokenHash),
    );
    if (existing == null) {
      return;
    }
    await DevtasksSession.db.updateRow(
      _session,
      existing.copyWith(revokedAt: revokedAt),
      columns: (t) => [t.revokedAt],
    );
  }
}

