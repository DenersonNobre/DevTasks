import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/workspace/domain/workspace_entity.dart';
import 'package:devtasks_server/src/modules/workspace/membership_guard.dart';
import 'package:devtasks_server/src/modules/workspace/ports.dart';
import 'package:devtasks_server/src/modules/workspace/workspace_service.dart';
import 'package:test/test.dart';

/// Repositório fake mínimo para exercitar apenas a autorização do guard.
class _FakeMembershipRepository implements WorkspaceRepository {
  _FakeMembershipRepository(this._roles);

  /// Chave: `workspaceId:userId` → papel.
  final Map<String, WorkspaceMemberRole> _roles;

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required int workspaceId,
    required String userId,
  }) async =>
      _roles['$workspaceId:$userId'];

  @override
  Future<WorkspaceEntity?> findById(int id) async => null;

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async => const [];

  @override
  Future<WorkspaceEntity?> updateName({
    required int workspaceId,
    required String name,
  }) async =>
      null;

  @override
  Future<WorkspaceWithRole> addMember({
    required int workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> removeMember({
    required int workspaceId,
    required String userId,
  }) async =>
      false;
}

void main() {
  const workspaceId = 10;

  MembershipGuard guardWith(Map<String, WorkspaceMemberRole> roles) =>
      MembershipGuard(_FakeMembershipRepository(roles));

  group('UC-02.03 — MembershipGuard (INV-06 / INV-01)', () {
    test('owner é autorizado e o papel fica comprovado', () async {
      final guard = guardWith({'$workspaceId:owner-1': WorkspaceMemberRole.owner});

      final result = await guard.authorizeOwner(
        workspaceId: workspaceId,
        userId: 'owner-1',
      );

      expect(result, isA<MembershipAuthAllowed>());
      expect(
        (result as MembershipAuthAllowed).role,
        WorkspaceMemberRole.owner,
      );
    });

    test('developer recebe ERR_INSUFFICIENT_ROLE (INV-06)', () async {
      final guard = guardWith({'$workspaceId:dev-1': WorkspaceMemberRole.developer});

      final result = await guard.authorizeOwner(
        workspaceId: workspaceId,
        userId: 'dev-1',
      );

      expect(result, isA<MembershipAuthDenied>());
      expect(
        (result as MembershipAuthDenied).errorCode,
        WorkspaceErrorCodes.insufficientRole,
      );
    });

    test('viewer recebe ERR_INSUFFICIENT_ROLE (INV-06)', () async {
      final guard = guardWith({'$workspaceId:viewer-1': WorkspaceMemberRole.viewer});

      final result = await guard.authorizeOwner(
        workspaceId: workspaceId,
        userId: 'viewer-1',
      );

      expect(result, isA<MembershipAuthDenied>());
      expect(
        (result as MembershipAuthDenied).errorCode,
        WorkspaceErrorCodes.insufficientRole,
      );
    });

    test(
      'não-membro e workspace inexistente devolvem o MESMO ERR_NOT_FOUND (INV-01)',
      () async {
        final nonMember = guardWith({});
        final outsider = guardWith({'$workspaceId:owner-1': WorkspaceMemberRole.owner});

        final resultNonMember = await nonMember.authorizeOwner(
          workspaceId: workspaceId,
          userId: 'stranger',
        );
        final resultInexistent = await outsider.authorizeOwner(
          workspaceId: 999,
          userId: 'stranger',
        );

        expect(resultNonMember, isA<MembershipAuthDenied>());
        expect(resultInexistent, isA<MembershipAuthDenied>());
        expect(
          (resultNonMember as MembershipAuthDenied).errorCode,
          WorkspaceErrorCodes.notFound,
        );
        expect(
          (resultInexistent as MembershipAuthDenied).errorCode,
          (resultNonMember).errorCode,
        );
      },
    );

    test('canMutate espelha authorizeOwner', () async {
      final owner = guardWith({'$workspaceId:owner-1': WorkspaceMemberRole.owner});
      final developer = guardWith({'$workspaceId:dev-1': WorkspaceMemberRole.developer});

      expect(
        await owner.canMutate(workspaceId: workspaceId, userId: 'owner-1'),
        isTrue,
      );
      expect(
        await developer.canMutate(workspaceId: workspaceId, userId: 'dev-1'),
        isFalse,
      );
    });
  });
}
