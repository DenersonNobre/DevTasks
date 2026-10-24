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
import 'project_dto.dart' as _i2;
import 'package:devtasks_client/src/protocol/protocol.dart' as _i3;

abstract class ProjectResultDto implements _i1.SerializableModel {
  ProjectResultDto._({
    required this.success,
    this.project,
    this.errorCode,
    this.message,
    this.field,
  });

  factory ProjectResultDto({
    required bool success,
    _i2.ProjectDto? project,
    String? errorCode,
    String? message,
    String? field,
  }) = _ProjectResultDtoImpl;

  factory ProjectResultDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProjectResultDto(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      project: jsonSerialization['project'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.ProjectDto>(
              jsonSerialization['project'],
            ),
      errorCode: jsonSerialization['errorCode'] as String?,
      message: jsonSerialization['message'] as String?,
      field: jsonSerialization['field'] as String?,
    );
  }

  bool success;

  _i2.ProjectDto? project;

  String? errorCode;

  String? message;

  String? field;

  /// Returns a shallow copy of this [ProjectResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProjectResultDto copyWith({
    bool? success,
    _i2.ProjectDto? project,
    String? errorCode,
    String? message,
    String? field,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectResultDto',
      'success': success,
      if (project != null) 'project': project?.toJson(),
      if (errorCode != null) 'errorCode': errorCode,
      if (message != null) 'message': message,
      if (field != null) 'field': field,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectResultDtoImpl extends ProjectResultDto {
  _ProjectResultDtoImpl({
    required bool success,
    _i2.ProjectDto? project,
    String? errorCode,
    String? message,
    String? field,
  }) : super._(
         success: success,
         project: project,
         errorCode: errorCode,
         message: message,
         field: field,
       );

  /// Returns a shallow copy of this [ProjectResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProjectResultDto copyWith({
    bool? success,
    Object? project = _Undefined,
    Object? errorCode = _Undefined,
    Object? message = _Undefined,
    Object? field = _Undefined,
  }) {
    return ProjectResultDto(
      success: success ?? this.success,
      project: project is _i2.ProjectDto? ? project : this.project?.copyWith(),
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      message: message is String? ? message : this.message,
      field: field is String? ? field : this.field,
    );
  }
}
