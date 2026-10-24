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
import 'devtasks_project.dart' as _i4;
import 'devtasks_session.dart' as _i5;
import 'devtasks_workspace.dart' as _i6;
import 'devtasks_workspace_member.dart' as _i7;
import 'me_result_dto.dart' as _i8;
import 'project_dto.dart' as _i9;
import 'project_list_result_dto.dart' as _i10;
import 'project_result_dto.dart' as _i11;
import 'sign_in_dto.dart' as _i12;
import 'sign_in_result_dto.dart' as _i13;
import 'sign_out_result_dto.dart' as _i14;
import 'sign_up_dto.dart' as _i15;
import 'sign_up_result_dto.dart' as _i16;
import 'workspace_dto.dart' as _i17;
import 'workspace_list_result_dto.dart' as _i18;
import 'workspace_member_role.dart' as _i19;
import 'workspace_result_dto.dart' as _i20;
export 'devtasks_project.dart';
export 'devtasks_session.dart';
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

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'devtasks_project',
      dartName: 'DevtasksProject',
      schema: 'public',
      module: 'devtasks',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'devtasks_project_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'workspaceId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
          indexName: 'devtasks_project_pkey',
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

    if (t == _i4.DevtasksProject) {
      return _i4.DevtasksProject.fromJson(data) as T;
    }
    if (t == _i5.DevtasksSession) {
      return _i5.DevtasksSession.fromJson(data) as T;
    }
    if (t == _i6.DevtasksWorkspace) {
      return _i6.DevtasksWorkspace.fromJson(data) as T;
    }
    if (t == _i7.DevtasksWorkspaceMember) {
      return _i7.DevtasksWorkspaceMember.fromJson(data) as T;
    }
    if (t == _i8.MeResultDto) {
      return _i8.MeResultDto.fromJson(data) as T;
    }
    if (t == _i9.ProjectDto) {
      return _i9.ProjectDto.fromJson(data) as T;
    }
    if (t == _i10.ProjectListResultDto) {
      return _i10.ProjectListResultDto.fromJson(data) as T;
    }
    if (t == _i11.ProjectResultDto) {
      return _i11.ProjectResultDto.fromJson(data) as T;
    }
    if (t == _i12.SignInDto) {
      return _i12.SignInDto.fromJson(data) as T;
    }
    if (t == _i13.SignInResultDto) {
      return _i13.SignInResultDto.fromJson(data) as T;
    }
    if (t == _i14.SignOutResultDto) {
      return _i14.SignOutResultDto.fromJson(data) as T;
    }
    if (t == _i15.SignUpDto) {
      return _i15.SignUpDto.fromJson(data) as T;
    }
    if (t == _i16.SignUpResultDto) {
      return _i16.SignUpResultDto.fromJson(data) as T;
    }
    if (t == _i17.WorkspaceDto) {
      return _i17.WorkspaceDto.fromJson(data) as T;
    }
    if (t == _i18.WorkspaceListResultDto) {
      return _i18.WorkspaceListResultDto.fromJson(data) as T;
    }
    if (t == _i19.WorkspaceMemberRole) {
      return _i19.WorkspaceMemberRole.fromJson(data) as T;
    }
    if (t == _i20.WorkspaceResultDto) {
      return _i20.WorkspaceResultDto.fromJson(data) as T;
    }
    if (t == _i1.getType<_i4.DevtasksProject?>()) {
      return (data != null ? _i4.DevtasksProject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.DevtasksSession?>()) {
      return (data != null ? _i5.DevtasksSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.DevtasksWorkspace?>()) {
      return (data != null ? _i6.DevtasksWorkspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.DevtasksWorkspaceMember?>()) {
      return (data != null ? _i7.DevtasksWorkspaceMember.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.MeResultDto?>()) {
      return (data != null ? _i8.MeResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ProjectDto?>()) {
      return (data != null ? _i9.ProjectDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ProjectListResultDto?>()) {
      return (data != null ? _i10.ProjectListResultDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.ProjectResultDto?>()) {
      return (data != null ? _i11.ProjectResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.SignInDto?>()) {
      return (data != null ? _i12.SignInDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.SignInResultDto?>()) {
      return (data != null ? _i13.SignInResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.SignOutResultDto?>()) {
      return (data != null ? _i14.SignOutResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.SignUpDto?>()) {
      return (data != null ? _i15.SignUpDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.SignUpResultDto?>()) {
      return (data != null ? _i16.SignUpResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.WorkspaceDto?>()) {
      return (data != null ? _i17.WorkspaceDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.WorkspaceListResultDto?>()) {
      return (data != null ? _i18.WorkspaceListResultDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.WorkspaceMemberRole?>()) {
      return (data != null ? _i19.WorkspaceMemberRole.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.WorkspaceResultDto?>()) {
      return (data != null ? _i20.WorkspaceResultDto.fromJson(data) : null)
          as T;
    }
    if (t == List<_i9.ProjectDto>) {
      return (data as List).map((e) => deserialize<_i9.ProjectDto>(e)).toList()
          as T;
    }
    if (t == List<_i17.WorkspaceDto>) {
      return (data as List)
              .map((e) => deserialize<_i17.WorkspaceDto>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i17.WorkspaceDto>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i17.WorkspaceDto>(e))
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
      _i4.DevtasksProject => 'DevtasksProject',
      _i5.DevtasksSession => 'DevtasksSession',
      _i6.DevtasksWorkspace => 'DevtasksWorkspace',
      _i7.DevtasksWorkspaceMember => 'DevtasksWorkspaceMember',
      _i8.MeResultDto => 'MeResultDto',
      _i9.ProjectDto => 'ProjectDto',
      _i10.ProjectListResultDto => 'ProjectListResultDto',
      _i11.ProjectResultDto => 'ProjectResultDto',
      _i12.SignInDto => 'SignInDto',
      _i13.SignInResultDto => 'SignInResultDto',
      _i14.SignOutResultDto => 'SignOutResultDto',
      _i15.SignUpDto => 'SignUpDto',
      _i16.SignUpResultDto => 'SignUpResultDto',
      _i17.WorkspaceDto => 'WorkspaceDto',
      _i18.WorkspaceListResultDto => 'WorkspaceListResultDto',
      _i19.WorkspaceMemberRole => 'WorkspaceMemberRole',
      _i20.WorkspaceResultDto => 'WorkspaceResultDto',
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
      case _i4.DevtasksProject():
        return 'DevtasksProject';
      case _i5.DevtasksSession():
        return 'DevtasksSession';
      case _i6.DevtasksWorkspace():
        return 'DevtasksWorkspace';
      case _i7.DevtasksWorkspaceMember():
        return 'DevtasksWorkspaceMember';
      case _i8.MeResultDto():
        return 'MeResultDto';
      case _i9.ProjectDto():
        return 'ProjectDto';
      case _i10.ProjectListResultDto():
        return 'ProjectListResultDto';
      case _i11.ProjectResultDto():
        return 'ProjectResultDto';
      case _i12.SignInDto():
        return 'SignInDto';
      case _i13.SignInResultDto():
        return 'SignInResultDto';
      case _i14.SignOutResultDto():
        return 'SignOutResultDto';
      case _i15.SignUpDto():
        return 'SignUpDto';
      case _i16.SignUpResultDto():
        return 'SignUpResultDto';
      case _i17.WorkspaceDto():
        return 'WorkspaceDto';
      case _i18.WorkspaceListResultDto():
        return 'WorkspaceListResultDto';
      case _i19.WorkspaceMemberRole():
        return 'WorkspaceMemberRole';
      case _i20.WorkspaceResultDto():
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
    if (dataClassName == 'DevtasksProject') {
      return deserialize<_i4.DevtasksProject>(data['data']);
    }
    if (dataClassName == 'DevtasksSession') {
      return deserialize<_i5.DevtasksSession>(data['data']);
    }
    if (dataClassName == 'DevtasksWorkspace') {
      return deserialize<_i6.DevtasksWorkspace>(data['data']);
    }
    if (dataClassName == 'DevtasksWorkspaceMember') {
      return deserialize<_i7.DevtasksWorkspaceMember>(data['data']);
    }
    if (dataClassName == 'MeResultDto') {
      return deserialize<_i8.MeResultDto>(data['data']);
    }
    if (dataClassName == 'ProjectDto') {
      return deserialize<_i9.ProjectDto>(data['data']);
    }
    if (dataClassName == 'ProjectListResultDto') {
      return deserialize<_i10.ProjectListResultDto>(data['data']);
    }
    if (dataClassName == 'ProjectResultDto') {
      return deserialize<_i11.ProjectResultDto>(data['data']);
    }
    if (dataClassName == 'SignInDto') {
      return deserialize<_i12.SignInDto>(data['data']);
    }
    if (dataClassName == 'SignInResultDto') {
      return deserialize<_i13.SignInResultDto>(data['data']);
    }
    if (dataClassName == 'SignOutResultDto') {
      return deserialize<_i14.SignOutResultDto>(data['data']);
    }
    if (dataClassName == 'SignUpDto') {
      return deserialize<_i15.SignUpDto>(data['data']);
    }
    if (dataClassName == 'SignUpResultDto') {
      return deserialize<_i16.SignUpResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceDto') {
      return deserialize<_i17.WorkspaceDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceListResultDto') {
      return deserialize<_i18.WorkspaceListResultDto>(data['data']);
    }
    if (dataClassName == 'WorkspaceMemberRole') {
      return deserialize<_i19.WorkspaceMemberRole>(data['data']);
    }
    if (dataClassName == 'WorkspaceResultDto') {
      return deserialize<_i20.WorkspaceResultDto>(data['data']);
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
      case _i4.DevtasksProject:
        return _i4.DevtasksProject.t;
      case _i5.DevtasksSession:
        return _i5.DevtasksSession.t;
      case _i6.DevtasksWorkspace:
        return _i6.DevtasksWorkspace.t;
      case _i7.DevtasksWorkspaceMember:
        return _i7.DevtasksWorkspaceMember.t;
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
