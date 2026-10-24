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
import 'devtasks_project.dart' as _i2;
import 'devtasks_workspace.dart' as _i3;
import 'devtasks_workspace_member.dart' as _i4;
import 'me_result_dto.dart' as _i5;
import 'project_dto.dart' as _i6;
import 'project_list_result_dto.dart' as _i7;
import 'project_result_dto.dart' as _i8;
import 'sign_in_dto.dart' as _i9;
import 'sign_in_result_dto.dart' as _i10;
import 'sign_out_result_dto.dart' as _i11;
import 'sign_up_dto.dart' as _i12;
import 'sign_up_result_dto.dart' as _i13;
import 'workspace_dto.dart' as _i14;
import 'workspace_list_result_dto.dart' as _i15;
import 'workspace_member_role.dart' as _i16;
import 'workspace_result_dto.dart' as _i17;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i18;
export 'devtasks_project.dart';
export 'devtasks_workspace.dart';
export 'devtasks_workspace_member.dart';
export 'me_result_dto.dart';
export 'project_dto.dart';
export 'project_list_result_dto.dart';
export 'project_result_dto.dart';
export 'sign_in_dto.dart';
export 'sign_in_result_dto.dart';
export 'sign_out_result_dto.dart';
export 'sign_up_dto.dart';
export 'sign_up_result_dto.dart';
export 'workspace_dto.dart';
export 'workspace_list_result_dto.dart';
export 'workspace_member_role.dart';
export 'workspace_result_dto.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.DevtasksProject) {
      return _i2.DevtasksProject.fromJson(data) as T;
    }
    if (t == _i3.DevtasksWorkspace) {
      return _i3.DevtasksWorkspace.fromJson(data) as T;
    }
    if (t == _i4.DevtasksWorkspaceMember) {
      return _i4.DevtasksWorkspaceMember.fromJson(data) as T;
    }
    if (t == _i5.MeResultDto) {
      return _i5.MeResultDto.fromJson(data) as T;
    }
    if (t == _i6.ProjectDto) {
      return _i6.ProjectDto.fromJson(data) as T;
    }
    if (t == _i7.ProjectListResultDto) {
      return _i7.ProjectListResultDto.fromJson(data) as T;
    }
    if (t == _i8.ProjectResultDto) {
      return _i8.ProjectResultDto.fromJson(data) as T;
    }
    if (t == _i9.SignInDto) {
      return _i9.SignInDto.fromJson(data) as T;
    }
    if (t == _i10.SignInResultDto) {
      return _i10.SignInResultDto.fromJson(data) as T;
    }
    if (t == _i11.SignOutResultDto) {
      return _i11.SignOutResultDto.fromJson(data) as T;
    }
    if (t == _i12.SignUpDto) {
      return _i12.SignUpDto.fromJson(data) as T;
    }
    if (t == _i13.SignUpResultDto) {
      return _i13.SignUpResultDto.fromJson(data) as T;
    }
    if (t == _i14.WorkspaceDto) {
      return _i14.WorkspaceDto.fromJson(data) as T;
    }
    if (t == _i15.WorkspaceListResultDto) {
      return _i15.WorkspaceListResultDto.fromJson(data) as T;
    }
    if (t == _i16.WorkspaceMemberRole) {
      return _i16.WorkspaceMemberRole.fromJson(data) as T;
    }
    if (t == _i17.WorkspaceResultDto) {
      return _i17.WorkspaceResultDto.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.DevtasksProject?>()) {
      return (data != null ? _i2.DevtasksProject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.DevtasksWorkspace?>()) {
      return (data != null ? _i3.DevtasksWorkspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.DevtasksWorkspaceMember?>()) {
      return (data != null ? _i4.DevtasksWorkspaceMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i5.MeResultDto?>()) {
      return (data != null ? _i5.MeResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ProjectDto?>()) {
      return (data != null ? _i6.ProjectDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.ProjectListResultDto?>()) {
      return (data != null ? _i7.ProjectListResultDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ProjectResultDto?>()) {
      return (data != null ? _i8.ProjectResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.SignInDto?>()) {
      return (data != null ? _i9.SignInDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.SignInResultDto?>()) {
      return (data != null ? _i10.SignInResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SignOutResultDto?>()) {
      return (data != null ? _i11.SignOutResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.SignUpDto?>()) {
      return (data != null ? _i12.SignUpDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.SignUpResultDto?>()) {
      return (data != null ? _i13.SignUpResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.WorkspaceDto?>()) {
      return (data != null ? _i14.WorkspaceDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.WorkspaceListResultDto?>()) {
      return (data != null ? _i15.WorkspaceListResultDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.WorkspaceMemberRole?>()) {
      return (data != null ? _i16.WorkspaceMemberRole.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.WorkspaceResultDto?>()) {
      return (data != null ? _i17.WorkspaceResultDto.fromJson(data) : null)
          as T;
    }
    if (t == List<_i6.ProjectDto>) {
      return (data as List).map((e) => deserialize<_i6.ProjectDto>(e)).toList()
          as T;
    }
    if (t == List<_i14.WorkspaceDto>) {
      return (data as List)
              .map((e) => deserialize<_i14.WorkspaceDto>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i14.WorkspaceDto>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i14.WorkspaceDto>(e))
                    .toList()
              : null)
          as T;
    }
    try {
      return _i18.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.DevtasksProject => 'DevtasksProject',
      _i3.DevtasksWorkspace => 'DevtasksWorkspace',
      _i4.DevtasksWorkspaceMember => 'DevtasksWorkspaceMember',
      _i5.MeResultDto => 'MeResultDto',
      _i6.ProjectDto => 'ProjectDto',
      _i7.ProjectListResultDto => 'ProjectListResultDto',
      _i8.ProjectResultDto => 'ProjectResultDto',
      _i9.SignInDto => 'SignInDto',
      _i10.SignInResultDto => 'SignInResultDto',
      _i11.SignOutResultDto => 'SignOutResultDto',
      _i12.SignUpDto => 'SignUpDto',
      _i13.SignUpResultDto => 'SignUpResultDto',
      _i14.WorkspaceDto => 'WorkspaceDto',
      _i15.WorkspaceListResultDto => 'WorkspaceListResultDto',
      _i16.WorkspaceMemberRole => 'WorkspaceMemberRole',
      _i17.WorkspaceResultDto => 'WorkspaceResultDto',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('devtasks.', '');
    }

    switch (data) {
      case _i2.DevtasksProject():
        return 'DevtasksProject';
      case _i3.DevtasksWorkspace():
        return 'DevtasksWorkspace';
      case _i4.DevtasksWorkspaceMember():
        return 'DevtasksWorkspaceMember';
      case _i5.MeResultDto():
        return 'MeResultDto';
      case _i6.ProjectDto():
        return 'ProjectDto';
      case _i7.ProjectListResultDto():
        return 'ProjectListResultDto';
      case _i8.ProjectResultDto():
        return 'ProjectResultDto';
      case _i9.SignInDto():
        return 'SignInDto';
      case _i10.SignInResultDto():
        return 'SignInResultDto';
      case _i11.SignOutResultDto():
        return 'SignOutResultDto';
      case _i12.SignUpDto():
        return 'SignUpDto';
      case _i13.SignUpResultDto():
        return 'SignUpResultDto';
      case _i14.WorkspaceDto():
        return 'WorkspaceDto';
      case _i15.WorkspaceListResultDto():
        return 'WorkspaceListResultDto';
      case _i16.WorkspaceMemberRole():
        return 'WorkspaceMemberRole';
      case _i17.WorkspaceResultDto():
        return 'WorkspaceResultDto';
    }
    className = _i18.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'DevtasksProject') {
      return deserialize<_i2.DevtasksProject>(data['data']);
    }
    if (dataClassName == 'DevtasksWorkspace') {
      return deserialize<_i3.DevtasksWorkspace>(data['data']);
    }
    if (dataClassName == 'DevtasksWorkspaceMember') {
      return deserialize<_i4.DevtasksWorkspaceMember>(data['data']);
    }
    if (dataClassName == 'MeResultDto') {
      return deserialize<_i5.MeResultDto>(data['data']);
    }
    if (dataClassName == 'ProjectDto') {
      return deserialize<_i6.ProjectDto>(data['data']);
    }
    if (dataClassName == 'ProjectListResultDto') {
      return deserialize<_i7.ProjectListResultDto>(data['data']);
    }
    if (dataClassName == 'ProjectResultDto') {
      return deserialize<_i8.ProjectResultDto>(data['data']);
    }
    if (dataClassName == 'SignInDto') {
      return deserialize<_i9.SignInDto>(data['data']);
    }
    if (dataClassName == 'SignInResultDto') {
      return deserialize<_i10.SignInResultDto>(data['data']);
    }
    if (dataClassName == 'SignOutResultDto') {
      return deserialize<_i11.SignOutResultDto>(data['data']);
    }
    if (dataClassName == 'SignUpDto') {
      return deserialize<_i12.SignUpDto>(data['data']);
    }
    if (dataClassName == 'SignUpResultDto') {
      return deserialize<_i13.SignUpResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceDto') {
      return deserialize<_i14.WorkspaceDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceListResultDto') {
      return deserialize<_i15.WorkspaceListResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceMemberRole') {
      return deserialize<_i16.WorkspaceMemberRole>(data['data']);
    }
    if (dataClassName == 'WorkspaceResultDto') {
      return deserialize<_i17.WorkspaceResultDto>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i18.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i18.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
