/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'workspace_member_role.dart' as _i2;

abstract class DevtasksWorkspaceMember implements _i1.SerializableModel {
  DevtasksWorkspaceMember._({
    this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
  });

  factory DevtasksWorkspaceMember({
    int? id,
    required int workspaceId,
    required String userId,
    required _i2.WorkspaceMemberRole role,
  }) = _DevtasksWorkspaceMemberImpl;

  factory DevtasksWorkspaceMember.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DevtasksWorkspaceMember(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      role: _i2.WorkspaceMemberRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String userId;

  _i2.WorkspaceMemberRole role;

  /// Returns a shallow copy of this [DevtasksWorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksWorkspaceMember copyWith({
    int? id,
    int? workspaceId,
    String? userId,
    _i2.WorkspaceMemberRole? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksWorkspaceMember',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DevtasksWorkspaceMemberImpl extends DevtasksWorkspaceMember {
  _DevtasksWorkspaceMemberImpl({
    int? id,
    required int workspaceId,
    required String userId,
    required _i2.WorkspaceMemberRole role,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         userId: userId,
         role: role,
       );

  /// Returns a shallow copy of this [DevtasksWorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksWorkspaceMember copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? userId,
    _i2.WorkspaceMemberRole? role,
  }) {
    return DevtasksWorkspaceMember(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}
