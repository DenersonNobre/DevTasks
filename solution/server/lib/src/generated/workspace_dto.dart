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

import 'package:serverpod/serverpod.dart' as _i1;
import 'workspace_member_role.dart' as _i2;

abstract class WorkspaceDto
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceDto._({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  factory WorkspaceDto({
    required int id,
    required String name,
    required _i2.WorkspaceMemberRole role,
    required DateTime createdAt,
  }) = _WorkspaceDtoImpl;

  factory WorkspaceDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceDto(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      role: _i2.WorkspaceMemberRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  String name;

  _i2.WorkspaceMemberRole role;

  DateTime createdAt;

  /// Returns a shallow copy of this [WorkspaceDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceDto copyWith({
    int? id,
    String? name,
    _i2.WorkspaceMemberRole? role,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceDto',
      'id': id,
      'name': name,
      'role': role.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceDto',
      'id': id,
      'name': name,
      'role': role.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _WorkspaceDtoImpl extends WorkspaceDto {
  _WorkspaceDtoImpl({
    required int id,
    required String name,
    required _i2.WorkspaceMemberRole role,
    required DateTime createdAt,
  }) : super._(
         id: id,
         name: name,
         role: role,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WorkspaceDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceDto copyWith({
    int? id,
    String? name,
    _i2.WorkspaceMemberRole? role,
    DateTime? createdAt,
  }) {
    return WorkspaceDto(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
