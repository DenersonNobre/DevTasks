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
import 'devtasks_workspace.dart' as _i2;
import 'devtasks_workspace_member.dart' as _i3;
import 'me_result_dto.dart' as _i4;
import 'sign_in_dto.dart' as _i5;
import 'sign_in_result_dto.dart' as _i6;
import 'sign_out_result_dto.dart' as _i7;
import 'sign_up_dto.dart' as _i8;
import 'sign_up_result_dto.dart' as _i9;
import 'workspace_dto.dart' as _i10;
import 'workspace_list_result_dto.dart' as _i11;
import 'workspace_member_role.dart' as _i12;
import 'workspace_result_dto.dart' as _i13;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i14;
export 'devtasks_workspace.dart';
export 'devtasks_workspace_member.dart';
export 'me_result_dto.dart';
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

    if (t == _i2.DevtasksWorkspace) {
      return _i2.DevtasksWorkspace.fromJson(data) as T;
    }
    if (t == _i3.DevtasksWorkspaceMember) {
      return _i3.DevtasksWorkspaceMember.fromJson(data) as T;
    }
    if (t == _i4.MeResultDto) {
      return _i4.MeResultDto.fromJson(data) as T;
    }
    if (t == _i5.SignInDto) {
      return _i5.SignInDto.fromJson(data) as T;
    }
    if (t == _i6.SignInResultDto) {
      return _i6.SignInResultDto.fromJson(data) as T;
    }
    if (t == _i7.SignOutResultDto) {
      return _i7.SignOutResultDto.fromJson(data) as T;
    }
    if (t == _i8.SignUpDto) {
      return _i8.SignUpDto.fromJson(data) as T;
    }
    if (t == _i9.SignUpResultDto) {
      return _i9.SignUpResultDto.fromJson(data) as T;
    }
    if (t == _i10.WorkspaceDto) {
      return _i10.WorkspaceDto.fromJson(data) as T;
    }
    if (t == _i11.WorkspaceListResultDto) {
      return _i11.WorkspaceListResultDto.fromJson(data) as T;
    }
    if (t == _i12.WorkspaceMemberRole) {
      return _i12.WorkspaceMemberRole.fromJson(data) as T;
    }
    if (t == _i13.WorkspaceResultDto) {
      return _i13.WorkspaceResultDto.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.DevtasksWorkspace?>()) {
      return (data != null ? _i2.DevtasksWorkspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.DevtasksWorkspaceMember?>()) {
      return (data != null ? _i3.DevtasksWorkspaceMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.MeResultDto?>()) {
      return (data != null ? _i4.MeResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.SignInDto?>()) {
      return (data != null ? _i5.SignInDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.SignInResultDto?>()) {
      return (data != null ? _i6.SignInResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.SignOutResultDto?>()) {
      return (data != null ? _i7.SignOutResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.SignUpDto?>()) {
      return (data != null ? _i8.SignUpDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.SignUpResultDto?>()) {
      return (data != null ? _i9.SignUpResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.WorkspaceDto?>()) {
      return (data != null ? _i10.WorkspaceDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.WorkspaceListResultDto?>()) {
      return (data != null ? _i11.WorkspaceListResultDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.WorkspaceMemberRole?>()) {
      return (data != null ? _i12.WorkspaceMemberRole.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.WorkspaceResultDto?>()) {
      return (data != null ? _i13.WorkspaceResultDto.fromJson(data) : null)
          as T;
    }
    if (t == List<_i10.WorkspaceDto>) {
      return (data as List)
              .map((e) => deserialize<_i10.WorkspaceDto>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i10.WorkspaceDto>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i10.WorkspaceDto>(e))
                    .toList()
              : null)
          as T;
    }
    try {
      return _i14.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.DevtasksWorkspace => 'DevtasksWorkspace',
      _i3.DevtasksWorkspaceMember => 'DevtasksWorkspaceMember',
      _i4.MeResultDto => 'MeResultDto',
      _i5.SignInDto => 'SignInDto',
      _i6.SignInResultDto => 'SignInResultDto',
      _i7.SignOutResultDto => 'SignOutResultDto',
      _i8.SignUpDto => 'SignUpDto',
      _i9.SignUpResultDto => 'SignUpResultDto',
      _i10.WorkspaceDto => 'WorkspaceDto',
      _i11.WorkspaceListResultDto => 'WorkspaceListResultDto',
      _i12.WorkspaceMemberRole => 'WorkspaceMemberRole',
      _i13.WorkspaceResultDto => 'WorkspaceResultDto',
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
      case _i2.DevtasksWorkspace():
        return 'DevtasksWorkspace';
      case _i3.DevtasksWorkspaceMember():
        return 'DevtasksWorkspaceMember';
      case _i4.MeResultDto():
        return 'MeResultDto';
      case _i5.SignInDto():
        return 'SignInDto';
      case _i6.SignInResultDto():
        return 'SignInResultDto';
      case _i7.SignOutResultDto():
        return 'SignOutResultDto';
      case _i8.SignUpDto():
        return 'SignUpDto';
      case _i9.SignUpResultDto():
        return 'SignUpResultDto';
      case _i10.WorkspaceDto():
        return 'WorkspaceDto';
      case _i11.WorkspaceListResultDto():
        return 'WorkspaceListResultDto';
      case _i12.WorkspaceMemberRole():
        return 'WorkspaceMemberRole';
      case _i13.WorkspaceResultDto():
        return 'WorkspaceResultDto';
    }
    className = _i14.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'DevtasksWorkspace') {
      return deserialize<_i2.DevtasksWorkspace>(data['data']);
    }
    if (dataClassName == 'DevtasksWorkspaceMember') {
      return deserialize<_i3.DevtasksWorkspaceMember>(data['data']);
    }
    if (dataClassName == 'MeResultDto') {
      return deserialize<_i4.MeResultDto>(data['data']);
    }
    if (dataClassName == 'SignInDto') {
      return deserialize<_i5.SignInDto>(data['data']);
    }
    if (dataClassName == 'SignInResultDto') {
      return deserialize<_i6.SignInResultDto>(data['data']);
    }
    if (dataClassName == 'SignOutResultDto') {
      return deserialize<_i7.SignOutResultDto>(data['data']);
    }
    if (dataClassName == 'SignUpDto') {
      return deserialize<_i8.SignUpDto>(data['data']);
    }
    if (dataClassName == 'SignUpResultDto') {
      return deserialize<_i9.SignUpResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceDto') {
      return deserialize<_i10.WorkspaceDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceListResultDto') {
      return deserialize<_i11.WorkspaceListResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceMemberRole') {
      return deserialize<_i12.WorkspaceMemberRole>(data['data']);
    }
    if (dataClassName == 'WorkspaceResultDto') {
      return deserialize<_i13.WorkspaceResultDto>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i14.Protocol().deserializeByClassName(data);
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
      return _i14.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
