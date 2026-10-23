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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i3;
import 'devtasks_session.dart' as _i4;
import 'devtasks_workspace.dart' as _i5;
import 'devtasks_workspace_member.dart' as _i6;
import 'me_result_dto.dart' as _i7;
import 'sign_in_dto.dart' as _i8;
import 'sign_in_result_dto.dart' as _i9;
import 'sign_out_result_dto.dart' as _i10;
import 'sign_up_dto.dart' as _i11;
import 'sign_up_result_dto.dart' as _i12;
import 'workspace_dto.dart' as _i13;
import 'workspace_list_result_dto.dart' as _i14;
import 'workspace_member_role.dart' as _i15;
import 'workspace_result_dto.dart' as _i16;
export 'devtasks_session.dart';
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

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'devtasks_session',
      dartName: 'DevtasksSession',
      schema: 'public',
      module: 'devtasks',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'devtasks_session_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'tokenHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'revokedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'devtasks_session_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'devtasks_session_token_hash_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'tokenHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'devtasks_workspace',
      dartName: 'DevtasksWorkspace',
      schema: 'public',
      module: 'devtasks',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'devtasks_workspace_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'devtasks_workspace_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'devtasks_workspace_member',
      dartName: 'DevtasksWorkspaceMember',
      schema: 'public',
      module: 'devtasks',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault:
              'nextval(\'devtasks_workspace_member_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:WorkspaceMemberRole',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'devtasks_workspace_member_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'devtasks_workspace_member_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'workspaceId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i4.DevtasksSession) {
      return _i4.DevtasksSession.fromJson(data) as T;
    }
    if (t == _i5.DevtasksWorkspace) {
      return _i5.DevtasksWorkspace.fromJson(data) as T;
    }
    if (t == _i6.DevtasksWorkspaceMember) {
      return _i6.DevtasksWorkspaceMember.fromJson(data) as T;
    }
    if (t == _i7.MeResultDto) {
      return _i7.MeResultDto.fromJson(data) as T;
    }
    if (t == _i8.SignInDto) {
      return _i8.SignInDto.fromJson(data) as T;
    }
    if (t == _i9.SignInResultDto) {
      return _i9.SignInResultDto.fromJson(data) as T;
    }
    if (t == _i10.SignOutResultDto) {
      return _i10.SignOutResultDto.fromJson(data) as T;
    }
    if (t == _i11.SignUpDto) {
      return _i11.SignUpDto.fromJson(data) as T;
    }
    if (t == _i12.SignUpResultDto) {
      return _i12.SignUpResultDto.fromJson(data) as T;
    }
    if (t == _i13.WorkspaceDto) {
      return _i13.WorkspaceDto.fromJson(data) as T;
    }
    if (t == _i14.WorkspaceListResultDto) {
      return _i14.WorkspaceListResultDto.fromJson(data) as T;
    }
    if (t == _i15.WorkspaceMemberRole) {
      return _i15.WorkspaceMemberRole.fromJson(data) as T;
    }
    if (t == _i16.WorkspaceResultDto) {
      return _i16.WorkspaceResultDto.fromJson(data) as T;
    }
    if (t == _i1.getType<_i4.DevtasksSession?>()) {
      return (data != null ? _i4.DevtasksSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.DevtasksWorkspace?>()) {
      return (data != null ? _i5.DevtasksWorkspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.DevtasksWorkspaceMember?>()) {
      return (data != null ? _i6.DevtasksWorkspaceMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.MeResultDto?>()) {
      return (data != null ? _i7.MeResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.SignInDto?>()) {
      return (data != null ? _i8.SignInDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.SignInResultDto?>()) {
      return (data != null ? _i9.SignInResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.SignOutResultDto?>()) {
      return (data != null ? _i10.SignOutResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SignUpDto?>()) {
      return (data != null ? _i11.SignUpDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.SignUpResultDto?>()) {
      return (data != null ? _i12.SignUpResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.WorkspaceDto?>()) {
      return (data != null ? _i13.WorkspaceDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.WorkspaceListResultDto?>()) {
      return (data != null ? _i14.WorkspaceListResultDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.WorkspaceMemberRole?>()) {
      return (data != null ? _i15.WorkspaceMemberRole.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.WorkspaceResultDto?>()) {
      return (data != null ? _i16.WorkspaceResultDto.fromJson(data) : null)
          as T;
    }
    if (t == List<_i13.WorkspaceDto>) {
      return (data as List)
              .map((e) => deserialize<_i13.WorkspaceDto>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i13.WorkspaceDto>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i13.WorkspaceDto>(e))
                    .toList()
              : null)
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i4.DevtasksSession => 'DevtasksSession',
      _i5.DevtasksWorkspace => 'DevtasksWorkspace',
      _i6.DevtasksWorkspaceMember => 'DevtasksWorkspaceMember',
      _i7.MeResultDto => 'MeResultDto',
      _i8.SignInDto => 'SignInDto',
      _i9.SignInResultDto => 'SignInResultDto',
      _i10.SignOutResultDto => 'SignOutResultDto',
      _i11.SignUpDto => 'SignUpDto',
      _i12.SignUpResultDto => 'SignUpResultDto',
      _i13.WorkspaceDto => 'WorkspaceDto',
      _i14.WorkspaceListResultDto => 'WorkspaceListResultDto',
      _i15.WorkspaceMemberRole => 'WorkspaceMemberRole',
      _i16.WorkspaceResultDto => 'WorkspaceResultDto',
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
      case _i4.DevtasksSession():
        return 'DevtasksSession';
      case _i5.DevtasksWorkspace():
        return 'DevtasksWorkspace';
      case _i6.DevtasksWorkspaceMember():
        return 'DevtasksWorkspaceMember';
      case _i7.MeResultDto():
        return 'MeResultDto';
      case _i8.SignInDto():
        return 'SignInDto';
      case _i9.SignInResultDto():
        return 'SignInResultDto';
      case _i10.SignOutResultDto():
        return 'SignOutResultDto';
      case _i11.SignUpDto():
        return 'SignUpDto';
      case _i12.SignUpResultDto():
        return 'SignUpResultDto';
      case _i13.WorkspaceDto():
        return 'WorkspaceDto';
      case _i14.WorkspaceListResultDto():
        return 'WorkspaceListResultDto';
      case _i15.WorkspaceMemberRole():
        return 'WorkspaceMemberRole';
      case _i16.WorkspaceResultDto():
        return 'WorkspaceResultDto';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'DevtasksSession') {
      return deserialize<_i4.DevtasksSession>(data['data']);
    }
    if (dataClassName == 'DevtasksWorkspace') {
      return deserialize<_i5.DevtasksWorkspace>(data['data']);
    }
    if (dataClassName == 'DevtasksWorkspaceMember') {
      return deserialize<_i6.DevtasksWorkspaceMember>(data['data']);
    }
    if (dataClassName == 'MeResultDto') {
      return deserialize<_i7.MeResultDto>(data['data']);
    }
    if (dataClassName == 'SignInDto') {
      return deserialize<_i8.SignInDto>(data['data']);
    }
    if (dataClassName == 'SignInResultDto') {
      return deserialize<_i9.SignInResultDto>(data['data']);
    }
    if (dataClassName == 'SignOutResultDto') {
      return deserialize<_i10.SignOutResultDto>(data['data']);
    }
    if (dataClassName == 'SignUpDto') {
      return deserialize<_i11.SignUpDto>(data['data']);
    }
    if (dataClassName == 'SignUpResultDto') {
      return deserialize<_i12.SignUpResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceDto') {
      return deserialize<_i13.WorkspaceDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceListResultDto') {
      return deserialize<_i14.WorkspaceListResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceMemberRole') {
      return deserialize<_i15.WorkspaceMemberRole>(data['data']);
    }
    if (dataClassName == 'WorkspaceResultDto') {
      return deserialize<_i16.WorkspaceResultDto>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i3.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i4.DevtasksSession:
        return _i4.DevtasksSession.t;
      case _i5.DevtasksWorkspace:
        return _i5.DevtasksWorkspace.t;
      case _i6.DevtasksWorkspaceMember:
        return _i6.DevtasksWorkspaceMember.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'devtasks';

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
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
