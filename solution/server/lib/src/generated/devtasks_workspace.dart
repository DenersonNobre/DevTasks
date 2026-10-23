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

abstract class DevtasksWorkspace
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  DevtasksWorkspace._({
    this.id,
    required this.name,
    required this.createdAt,
  });

  factory DevtasksWorkspace({
    int? id,
    required String name,
    required DateTime createdAt,
  }) = _DevtasksWorkspaceImpl;

  factory DevtasksWorkspace.fromJson(Map<String, dynamic> jsonSerialization) {
    return DevtasksWorkspace(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = DevtasksWorkspaceTable();

  static const db = DevtasksWorkspaceRepository._();

  @override
  int? id;

  String name;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [DevtasksWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksWorkspace copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksWorkspace',
      if (id != null) 'id': id,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DevtasksWorkspace',
      if (id != null) 'id': id,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  static DevtasksWorkspaceInclude include() {
    return DevtasksWorkspaceInclude._();
  }

  static DevtasksWorkspaceIncludeList includeList({
    _i1.WhereExpressionBuilder<DevtasksWorkspaceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksWorkspaceTable>? orderByList,
    DevtasksWorkspaceInclude? include,
  }) {
    return DevtasksWorkspaceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksWorkspace.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DevtasksWorkspace.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DevtasksWorkspaceImpl extends DevtasksWorkspace {
  _DevtasksWorkspaceImpl({
    int? id,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DevtasksWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksWorkspace copyWith({
    Object? id = _Undefined,
    String? name,
    DateTime? createdAt,
  }) {
    return DevtasksWorkspace(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DevtasksWorkspaceUpdateTable
    extends _i1.UpdateTable<DevtasksWorkspaceTable> {
  DevtasksWorkspaceUpdateTable(super.table);

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

class DevtasksWorkspaceTable extends _i1.Table<int?> {
  DevtasksWorkspaceTable({super.tableRelation})
    : super(tableName: 'devtasks_workspace') {
    updateTable = DevtasksWorkspaceUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DevtasksWorkspaceUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    createdAt,
  ];
}

class DevtasksWorkspaceInclude extends _i1.IncludeObject {
  DevtasksWorkspaceInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => DevtasksWorkspace.t;
}

class DevtasksWorkspaceIncludeList extends _i1.IncludeList {
  DevtasksWorkspaceIncludeList._({
    _i1.WhereExpressionBuilder<DevtasksWorkspaceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DevtasksWorkspace.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => DevtasksWorkspace.t;
}

class DevtasksWorkspaceRepository {
  const DevtasksWorkspaceRepository._();

  /// Returns a list of [DevtasksWorkspace]s matching the given query parameters.
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
  Future<List<DevtasksWorkspace>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksWorkspaceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksWorkspaceTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DevtasksWorkspace>(
      where: where?.call(DevtasksWorkspace.t),
      orderBy: orderBy?.call(DevtasksWorkspace.t),
      orderByList: orderByList?.call(DevtasksWorkspace.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DevtasksWorkspace] matching the given query parameters.
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
  Future<DevtasksWorkspace?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksWorkspaceTable>? where,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksWorkspaceTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DevtasksWorkspace>(
      where: where?.call(DevtasksWorkspace.t),
      orderBy: orderBy?.call(DevtasksWorkspace.t),
      orderByList: orderByList?.call(DevtasksWorkspace.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DevtasksWorkspace] by its [id] or null if no such row exists.
  Future<DevtasksWorkspace?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DevtasksWorkspace>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DevtasksWorkspace]s in the list and returns the inserted rows.
  ///
  /// The returned [DevtasksWorkspace]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<DevtasksWorkspace>> insert(
    _i1.DatabaseSession session,
    List<DevtasksWorkspace> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<DevtasksWorkspace>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [DevtasksWorkspace] and returns the inserted row.
  ///
  /// The returned [DevtasksWorkspace] will have its `id` field set.
  Future<DevtasksWorkspace> insertRow(
    _i1.DatabaseSession session,
    DevtasksWorkspace row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DevtasksWorkspace>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksWorkspace]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DevtasksWorkspace>> update(
    _i1.DatabaseSession session,
    List<DevtasksWorkspace> rows, {
    _i1.ColumnSelections<DevtasksWorkspaceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DevtasksWorkspace>(
      rows,
      columns: columns?.call(DevtasksWorkspace.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksWorkspace]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DevtasksWorkspace> updateRow(
    _i1.DatabaseSession session,
    DevtasksWorkspace row, {
    _i1.ColumnSelections<DevtasksWorkspaceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DevtasksWorkspace>(
      row,
      columns: columns?.call(DevtasksWorkspace.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksWorkspace] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DevtasksWorkspace?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<DevtasksWorkspaceUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DevtasksWorkspace>(
      id,
      columnValues: columnValues(DevtasksWorkspace.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksWorkspace]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DevtasksWorkspace>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DevtasksWorkspaceUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<DevtasksWorkspaceTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksWorkspaceTable>? orderBy,
    _i1.OrderByListBuilder<DevtasksWorkspaceTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DevtasksWorkspace>(
      columnValues: columnValues(DevtasksWorkspace.t.updateTable),
      where: where(DevtasksWorkspace.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksWorkspace.t),
      orderByList: orderByList?.call(DevtasksWorkspace.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DevtasksWorkspace]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DevtasksWorkspace>> delete(
    _i1.DatabaseSession session,
    List<DevtasksWorkspace> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DevtasksWorkspace>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DevtasksWorkspace].
  Future<DevtasksWorkspace> deleteRow(
    _i1.DatabaseSession session,
    DevtasksWorkspace row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DevtasksWorkspace>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DevtasksWorkspace>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksWorkspaceTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DevtasksWorkspace>(
      where: where(DevtasksWorkspace.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksWorkspaceTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DevtasksWorkspace>(
      where: where?.call(DevtasksWorkspace.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DevtasksWorkspace] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksWorkspaceTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DevtasksWorkspace>(
      where: where(DevtasksWorkspace.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
