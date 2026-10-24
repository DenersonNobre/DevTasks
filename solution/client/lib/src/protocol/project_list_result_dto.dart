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

abstract class ProjectListResultDto implements _i1.SerializableModel {
  ProjectListResultDto._({
    required this.success,
    required this.projects,
    this.errorCode,
    this.message,
  });

  factory ProjectListResultDto({
    required bool success,
    required List<_i2.ProjectDto> projects,
    String? errorCode,
    String? message,
  }) = _ProjectListResultDtoImpl;

  factory ProjectListResultDto.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProjectListResultDto(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      projects: _i3.Protocol().deserialize<List<_i2.ProjectDto>>(
        jsonSerialization['projects'],
      ),
      errorCode: jsonSerialization['errorCode'] as String?,
      message: jsonSerialization['message'] as String?,
    );
  }

  bool success;

  List<_i2.ProjectDto> projects;

  String? errorCode;

  String? message;

  /// Returns a shallow copy of this [ProjectListResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProjectListResultDto copyWith({
    bool? success,
    List<_i2.ProjectDto>? projects,
    String? errorCode,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectListResultDto',
      'success': success,
      'projects': projects.toJson(valueToJson: (v) => v.toJson()),
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

class _ProjectListResultDtoImpl extends ProjectListResultDto {
  _ProjectListResultDtoImpl({
    required bool success,
    required List<_i2.ProjectDto> projects,
    String? errorCode,
    String? message,
  }) : super._(
         success: success,
         projects: projects,
         errorCode: errorCode,
         message: message,
       );

  /// Returns a shallow copy of this [ProjectListResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProjectListResultDto copyWith({
    bool? success,
    List<_i2.ProjectDto>? projects,
    Object? errorCode = _Undefined,
    Object? message = _Undefined,
  }) {
    return ProjectListResultDto(
      success: success ?? this.success,
      projects: projects ?? this.projects.map((e0) => e0.copyWith()).toList(),
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      message: message is String? ? message : this.message,
    );
  }
}
