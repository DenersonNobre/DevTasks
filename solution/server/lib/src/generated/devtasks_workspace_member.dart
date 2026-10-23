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
import 'workspace_member_role.dart' as _i2;

abstract class DevtasksWorkspaceMember
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  DevtasksWorkspaceMember._({
    this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
  });

  factory DevtasksWorkspaceMember({
    int? id,
    required int workspaceId,
    required String userId,
    required _i2.WorkspaceMemberRole role,
  }) = _DevtasksWorkspaceMemberImpl;

  factory DevtasksWorkspaceMember.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DevtasksWorkspaceMember(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      role: _i2.WorkspaceMemberRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
    );
  }

  static final t = DevtasksWorkspaceMemberTable();

  static const db = DevtasksWorkspaceMemberRepository._();

  @override
  int? id;

  int workspaceId;

  String userId;

  _i2.WorkspaceMemberRole role;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [DevtasksWorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksWorkspaceMember copyWith({
    int? id,
    int? workspaceId,
    String? userId,
    _i2.WorkspaceMemberRole? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksWorkspaceMember',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DevtasksWorkspaceMember',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role.toJson(),
    };
  }

  static DevtasksWorkspaceMemberInclude include() {
    return DevtasksWorkspaceMemberInclude._();
  }

  static DevtasksWorkspaceMemberIncludeList includeList({
    _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksWorkspaceMemberTable>? orderByList,
    DevtasksWorkspaceMemberInclude? include,
  }) {
    return DevtasksWorkspaceMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksWorkspaceMember.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DevtasksWorkspaceMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DevtasksWorkspaceMemberImpl extends DevtasksWorkspaceMember {
  _DevtasksWorkspaceMemberImpl({
    int? id,
    required int workspaceId,
    required String userId,
    required _i2.WorkspaceMemberRole role,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         userId: userId,
         role: role,
       );

  /// Returns a shallow copy of this [DevtasksWorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksWorkspaceMember copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? userId,
    _i2.WorkspaceMemberRole? role,
  }) {
    return DevtasksWorkspaceMember(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}

class DevtasksWorkspaceMemberUpdateTable
    extends _i1.UpdateTable<DevtasksWorkspaceMemberTable> {
  DevtasksWorkspaceMemberUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<_i2.WorkspaceMemberRole, _i2.WorkspaceMemberRole> role(
    _i2.WorkspaceMemberRole value,
  ) => _i1.ColumnValue(
    table.role,
    value,
  );
}

class DevtasksWorkspaceMemberTable extends _i1.Table<int?> {
  DevtasksWorkspaceMemberTable({super.tableRelation})
    : super(tableName: 'devtasks_workspace_member') {
    updateTable = DevtasksWorkspaceMemberUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    role = _i1.ColumnEnum(
      'role',
      this,
      _i1.EnumSerialization.byName,
    );
  }

  late final DevtasksWorkspaceMemberUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnString userId;

  late final _i1.ColumnEnum<_i2.WorkspaceMemberRole> role;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    userId,
    role,
  ];
}

class DevtasksWorkspaceMemberInclude extends _i1.IncludeObject {
  DevtasksWorkspaceMemberInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => DevtasksWorkspaceMember.t;
}

class DevtasksWorkspaceMemberIncludeList extends _i1.IncludeList {
  DevtasksWorkspaceMemberIncludeList._({
    _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DevtasksWorkspaceMember.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => DevtasksWorkspaceMember.t;
}

class DevtasksWorkspaceMemberRepository {
  const DevtasksWorkspaceMemberRepository._();

  /// Returns a list of [DevtasksWorkspaceMember]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<DevtasksWorkspaceMember>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksWorkspaceMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DevtasksWorkspaceMember>(
      where: where?.call(DevtasksWorkspaceMember.t),
      orderBy: orderBy?.call(DevtasksWorkspaceMember.t),
      orderByList: orderByList?.call(DevtasksWorkspaceMember.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DevtasksWorkspaceMember] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<DevtasksWorkspaceMember?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable>? where,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceMemberTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksWorkspaceMemberTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DevtasksWorkspaceMember>(
      where: where?.call(DevtasksWorkspaceMember.t),
      orderBy: orderBy?.call(DevtasksWorkspaceMember.t),
      orderByList: orderByList?.call(DevtasksWorkspaceMember.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DevtasksWorkspaceMember] by its [id] or null if no such row exists.
  Future<DevtasksWorkspaceMember?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DevtasksWorkspaceMember>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DevtasksWorkspaceMember]s in the list and returns the inserted rows.
  ///
  /// The returned [DevtasksWorkspaceMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<DevtasksWorkspaceMember>> insert(
    _i1.DatabaseSession session,
    List<DevtasksWorkspaceMember> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<DevtasksWorkspaceMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [DevtasksWorkspaceMember] and returns the inserted row.
  ///
  /// The returned [DevtasksWorkspaceMember] will have its `id` field set.
  Future<DevtasksWorkspaceMember> insertRow(
    _i1.DatabaseSession session,
    DevtasksWorkspaceMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DevtasksWorkspaceMember>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksWorkspaceMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DevtasksWorkspaceMember>> update(
    _i1.DatabaseSession session,
    List<DevtasksWorkspaceMember> rows, {
    _i1.ColumnSelections<DevtasksWorkspaceMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DevtasksWorkspaceMember>(
      rows,
      columns: columns?.call(DevtasksWorkspaceMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksWorkspaceMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DevtasksWorkspaceMember> updateRow(
    _i1.DatabaseSession session,
    DevtasksWorkspaceMember row, {
    _i1.ColumnSelections<DevtasksWorkspaceMemberTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DevtasksWorkspaceMember>(
      row,
      columns: columns?.call(DevtasksWorkspaceMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksWorkspaceMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DevtasksWorkspaceMember?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<DevtasksWorkspaceMemberUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DevtasksWorkspaceMember>(
      id,
      columnValues: columnValues(DevtasksWorkspaceMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksWorkspaceMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DevtasksWorkspaceMember>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DevtasksWorkspaceMemberUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceMemberTable>? orderBy,
    _i1.OrderByListBuilder<DevtasksWorkspaceMemberTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DevtasksWorkspaceMember>(
      columnValues: columnValues(DevtasksWorkspaceMember.t.updateTable),
      where: where(DevtasksWorkspaceMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksWorkspaceMember.t),
      orderByList: orderByList?.call(DevtasksWorkspaceMember.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DevtasksWorkspaceMember]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DevtasksWorkspaceMember>> delete(
    _i1.DatabaseSession session,
    List<DevtasksWorkspaceMember> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DevtasksWorkspaceMember>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DevtasksWorkspaceMember].
  Future<DevtasksWorkspaceMember> deleteRow(
    _i1.DatabaseSession session,
    DevtasksWorkspaceMember row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DevtasksWorkspaceMember>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DevtasksWorkspaceMember>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DevtasksWorkspaceMember>(
      where: where(DevtasksWorkspaceMember.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DevtasksWorkspaceMember>(
      where: where?.call(DevtasksWorkspaceMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DevtasksWorkspaceMember] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksWorkspaceMemberTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DevtasksWorkspaceMember>(
      where: where(DevtasksWorkspaceMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
