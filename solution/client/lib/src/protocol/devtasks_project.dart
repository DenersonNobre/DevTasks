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

abstract class DevtasksProject implements _i1.SerializableModel {
  DevtasksProject._({
    this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
  });

  factory DevtasksProject({
    int? id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
  }) = _DevtasksProjectImpl;

  factory DevtasksProject.fromJson(Map<String, dynamic> jsonSerialization) {
    return DevtasksProject(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String name;

  DateTime createdAt;

  /// Returns a shallow copy of this [DevtasksProject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksProject copyWith({
    int? id,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksProject',
      if (id != null) 'id': id,
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

class _Undefined {}

class _DevtasksProjectImpl extends DevtasksProject {
  _DevtasksProjectImpl({
    int? id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DevtasksProject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksProject copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
  }) {
    return DevtasksProject(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
