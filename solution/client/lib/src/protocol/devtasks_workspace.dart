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

abstract class DevtasksWorkspace implements _i1.SerializableModel {
  DevtasksWorkspace._({
    this.id,
    required this.name,
    required this.createdAt,
  });

  factory DevtasksWorkspace({
    int? id,
    required String name,
    required DateTime createdAt,
  }) = _DevtasksWorkspaceImpl;

  factory DevtasksWorkspace.fromJson(Map<String, dynamic> jsonSerialization) {
    return DevtasksWorkspace(
      id: jsonSerialization['id'] as int?,
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

  String name;

  DateTime createdAt;

  /// Returns a shallow copy of this [DevtasksWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksWorkspace copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksWorkspace',
      if (id != null) 'id': id,
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

class _DevtasksWorkspaceImpl extends DevtasksWorkspace {
  _DevtasksWorkspaceImpl({
    int? id,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DevtasksWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksWorkspace copyWith({
    Object? id = _Undefined,
    String? name,
    DateTime? createdAt,
  }) {
    return DevtasksWorkspace(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
