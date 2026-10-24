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

abstract class DevtasksProject
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  DevtasksProject._({
    this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
  });

  factory DevtasksProject({
    int? id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
  }) = _DevtasksProjectImpl;

  factory DevtasksProject.fromJson(Map<String, dynamic> jsonSerialization) {
    return DevtasksProject(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = DevtasksProjectTable();

  static const db = DevtasksProjectRepository._();

  @override
  int? id;

  int workspaceId;

  String name;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [DevtasksProject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksProject copyWith({
    int? id,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksProject',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DevtasksProject',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  static DevtasksProjectInclude include() {
    return DevtasksProjectInclude._();
  }

  static DevtasksProjectIncludeList includeList({
    _i1.WhereExpressionBuilder<DevtasksProjectTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksProjectTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksProjectTable>? orderByList,
    DevtasksProjectInclude? include,
  }) {
    return DevtasksProjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksProject.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DevtasksProject.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DevtasksProjectImpl extends DevtasksProject {
  _DevtasksProjectImpl({
    int? id,
    required int workspaceId,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DevtasksProject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksProject copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? name,
    DateTime? createdAt,
  }) {
    return DevtasksProject(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DevtasksProjectUpdateTable extends _i1.UpdateTable<DevtasksProjectTable> {
  DevtasksProjectUpdateTable(super.table);

  _i1.ColumnValue<int, int> workspaceId(int value) => _i1.ColumnValue(
    table.workspaceId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class DevtasksProjectTable extends _i1.Table<int?> {
  DevtasksProjectTable({super.tableRelation})
    : super(tableName: 'devtasks_project') {
    updateTable = DevtasksProjectUpdateTable(this);
    workspaceId = _i1.ColumnInt(
      'workspaceId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DevtasksProjectUpdateTable updateTable;

  late final _i1.ColumnInt workspaceId;

  late final _i1.ColumnString name;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    workspaceId,
    name,
    createdAt,
  ];
}

class DevtasksProjectInclude extends _i1.IncludeObject {
  DevtasksProjectInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => DevtasksProject.t;
}

class DevtasksProjectIncludeList extends _i1.IncludeList {
  DevtasksProjectIncludeList._({
    _i1.WhereExpressionBuilder<DevtasksProjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DevtasksProject.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => DevtasksProject.t;
}

class DevtasksProjectRepository {
  const DevtasksProjectRepository._();

  /// Returns a list of [DevtasksProject]s matching the given query parameters.
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
  Future<List<DevtasksProject>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksProjectTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksProjectTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksProjectTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DevtasksProject>(
      where: where?.call(DevtasksProject.t),
      orderBy: orderBy?.call(DevtasksProject.t),
      orderByList: orderByList?.call(DevtasksProject.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DevtasksProject] matching the given query parameters.
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
  Future<DevtasksProject?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksProjectTable>? where,
    int? offset,
    _i1.OrderByBuilder<DevtasksProjectTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksProjectTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DevtasksProject>(
      where: where?.call(DevtasksProject.t),
      orderBy: orderBy?.call(DevtasksProject.t),
      orderByList: orderByList?.call(DevtasksProject.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DevtasksProject] by its [id] or null if no such row exists.
  Future<DevtasksProject?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DevtasksProject>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DevtasksProject]s in the list and returns the inserted rows.
  ///
  /// The returned [DevtasksProject]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<DevtasksProject>> insert(
    _i1.DatabaseSession session,
    List<DevtasksProject> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<DevtasksProject>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [DevtasksProject] and returns the inserted row.
  ///
  /// The returned [DevtasksProject] will have its `id` field set.
  Future<DevtasksProject> insertRow(
    _i1.DatabaseSession session,
    DevtasksProject row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DevtasksProject>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksProject]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DevtasksProject>> update(
    _i1.DatabaseSession session,
    List<DevtasksProject> rows, {
    _i1.ColumnSelections<DevtasksProjectTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DevtasksProject>(
      rows,
      columns: columns?.call(DevtasksProject.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksProject]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DevtasksProject> updateRow(
    _i1.DatabaseSession session,
    DevtasksProject row, {
    _i1.ColumnSelections<DevtasksProjectTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DevtasksProject>(
      row,
      columns: columns?.call(DevtasksProject.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksProject] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DevtasksProject?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<DevtasksProjectUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DevtasksProject>(
      id,
      columnValues: columnValues(DevtasksProject.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksProject]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DevtasksProject>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DevtasksProjectUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<DevtasksProjectTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksProjectTable>? orderBy,
    _i1.OrderByListBuilder<DevtasksProjectTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DevtasksProject>(
      columnValues: columnValues(DevtasksProject.t.updateTable),
      where: where(DevtasksProject.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksProject.t),
      orderByList: orderByList?.call(DevtasksProject.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DevtasksProject]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DevtasksProject>> delete(
    _i1.DatabaseSession session,
    List<DevtasksProject> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DevtasksProject>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DevtasksProject].
  Future<DevtasksProject> deleteRow(
    _i1.DatabaseSession session,
    DevtasksProject row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DevtasksProject>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DevtasksProject>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksProjectTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DevtasksProject>(
      where: where(DevtasksProject.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksProjectTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DevtasksProject>(
      where: where?.call(DevtasksProject.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DevtasksProject] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksProjectTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DevtasksProject>(
      where: where(DevtasksProject.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
