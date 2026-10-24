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

abstract class ProjectDto
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ProjectDto._({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
  });

  factory ProjectDto({
    required int id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
  }) = _ProjectDtoImpl;

  factory ProjectDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProjectDto(
      id: jsonSerialization['id'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  int workspaceId;

  String name;

  DateTime createdAt;

  /// Returns a shallow copy of this [ProjectDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProjectDto copyWith({
    int? id,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectDto',
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProjectDto',
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ProjectDtoImpl extends ProjectDto {
  _ProjectDtoImpl({
    required int id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ProjectDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProjectDto copyWith({
    int? id,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
  }) {
    return ProjectDto(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
