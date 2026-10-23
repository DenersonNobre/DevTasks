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

abstract class DevtasksSession implements _i1.SerializableModel {
  DevtasksSession._({
    this.id,
    required this.userId,
    required this.tokenHash,
    required this.createdAt,
    required this.expiresAt,
    this.revokedAt,
  });

  factory DevtasksSession({
    int? id,
    required String userId,
    required String tokenHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) = _DevtasksSessionImpl;

  factory DevtasksSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return DevtasksSession(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      tokenHash: jsonSerialization['tokenHash'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  String tokenHash;

  DateTime createdAt;

  DateTime expiresAt;

  DateTime? revokedAt;

  /// Returns a shallow copy of this [DevtasksSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksSession copyWith({
    int? id,
    String? userId,
    String? tokenHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksSession',
      if (id != null) 'id': id,
      'userId': userId,
      'tokenHash': tokenHash,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DevtasksSessionImpl extends DevtasksSession {
  _DevtasksSessionImpl({
    int? id,
    required String userId,
    required String tokenHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) : super._(
         id: id,
         userId: userId,
         tokenHash: tokenHash,
         createdAt: createdAt,
         expiresAt: expiresAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [DevtasksSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksSession copyWith({
    Object? id = _Undefined,
    String? userId,
    String? tokenHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? revokedAt = _Undefined,
  }) {
    return DevtasksSession(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      tokenHash: tokenHash ?? this.tokenHash,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}
