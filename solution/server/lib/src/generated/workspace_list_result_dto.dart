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
import 'workspace_dto.dart' as _i2;
import 'package:devtasks_server/src/generated/protocol.dart' as _i3;

abstract class WorkspaceListResultDto
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceListResultDto._({
    required this.success,
    this.workspaces,
    this.errorCode,
    this.message,
  });

  factory WorkspaceListResultDto({
    required bool success,
    List<_i2.WorkspaceDto>? workspaces,
    String? errorCode,
    String? message,
  }) = _WorkspaceListResultDtoImpl;

  factory WorkspaceListResultDto.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceListResultDto(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      workspaces: jsonSerialization['workspaces'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.WorkspaceDto>>(
              jsonSerialization['workspaces'],
            ),
      errorCode: jsonSerialization['errorCode'] as String?,
      message: jsonSerialization['message'] as String?,
    );
  }

  bool success;

  List<_i2.WorkspaceDto>? workspaces;

  String? errorCode;

  String? message;

  /// Returns a shallow copy of this [WorkspaceListResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceListResultDto copyWith({
    bool? success,
    List<_i2.WorkspaceDto>? workspaces,
    String? errorCode,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceListResultDto',
      'success': success,
      if (workspaces != null)
        'workspaces': workspaces?.toJson(valueToJson: (v) => v.toJson()),
      if (errorCode != null) 'errorCode': errorCode,
      if (message != null) 'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceListResultDto',
      'success': success,
      if (workspaces != null)
        'workspaces': workspaces?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (errorCode != null) 'errorCode': errorCode,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceListResultDtoImpl extends WorkspaceListResultDto {
  _WorkspaceListResultDtoImpl({
    required bool success,
    List<_i2.WorkspaceDto>? workspaces,
    String? errorCode,
    String? message,
  }) : super._(
         success: success,
         workspaces: workspaces,
         errorCode: errorCode,
         message: message,
       );

  /// Returns a shallow copy of this [WorkspaceListResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceListResultDto copyWith({
    bool? success,
    Object? workspaces = _Undefined,
    Object? errorCode = _Undefined,
    Object? message = _Undefined,
  }) {
    return WorkspaceListResultDto(
      success: success ?? this.success,
      workspaces: workspaces is List<_i2.WorkspaceDto>?
          ? workspaces
          : this.workspaces?.map((e0) => e0.copyWith()).toList(),
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      message: message is String? ? message : this.message,
    );
  }
}
