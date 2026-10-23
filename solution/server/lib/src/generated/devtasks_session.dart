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

abstract class DevtasksSession
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  DevtasksSession._({
    this.id,
    required this.userId,
    required this.tokenHash,
    required this.createdAt,
    required this.expiresAt,
    this.revokedAt,
  });

  factory DevtasksSession({
    int? id,
    required String userId,
    required String tokenHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) = _DevtasksSessionImpl;

  factory DevtasksSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return DevtasksSession(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      tokenHash: jsonSerialization['tokenHash'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  static final t = DevtasksSessionTable();

  static const db = DevtasksSessionRepository._();

  @override
  int? id;

  String userId;

  String tokenHash;

  DateTime createdAt;

  DateTime expiresAt;

  DateTime? revokedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [DevtasksSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DevtasksSession copyWith({
    int? id,
    String? userId,
    String? tokenHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DevtasksSession',
      if (id != null) 'id': id,
      'userId': userId,
      'tokenHash': tokenHash,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DevtasksSessionInclude include() {
    return DevtasksSessionInclude._();
  }

  static DevtasksSessionIncludeList includeList({
    _i1.WhereExpressionBuilder<DevtasksSessionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksSessionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksSessionTable>? orderByList,
    DevtasksSessionInclude? include,
  }) {
    return DevtasksSessionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksSession.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DevtasksSession.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DevtasksSessionImpl extends DevtasksSession {
  _DevtasksSessionImpl({
    int? id,
    required String userId,
    required String tokenHash,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revokedAt,
  }) : super._(
         id: id,
         userId: userId,
         tokenHash: tokenHash,
         createdAt: createdAt,
         expiresAt: expiresAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [DevtasksSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DevtasksSession copyWith({
    Object? id = _Undefined,
    String? userId,
    String? tokenHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? revokedAt = _Undefined,
  }) {
    return DevtasksSession(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      tokenHash: tokenHash ?? this.tokenHash,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}

class DevtasksSessionUpdateTable extends _i1.UpdateTable<DevtasksSessionTable> {
  DevtasksSessionUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> tokenHash(String value) => _i1.ColumnValue(
    table.tokenHash,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> revokedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.revokedAt,
        value,
      );
}

class DevtasksSessionTable extends _i1.Table<int?> {
  DevtasksSessionTable({super.tableRelation})
    : super(tableName: 'devtasks_session') {
    updateTable = DevtasksSessionUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    tokenHash = _i1.ColumnString(
      'tokenHash',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    revokedAt = _i1.ColumnDateTime(
      'revokedAt',
      this,
    );
  }

  late final DevtasksSessionUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString tokenHash;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnDateTime revokedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    tokenHash,
    createdAt,
    expiresAt,
    revokedAt,
  ];
}

class DevtasksSessionInclude extends _i1.IncludeObject {
  DevtasksSessionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => DevtasksSession.t;
}

class DevtasksSessionIncludeList extends _i1.IncludeList {
  DevtasksSessionIncludeList._({
    _i1.WhereExpressionBuilder<DevtasksSessionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DevtasksSession.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => DevtasksSession.t;
}

class DevtasksSessionRepository {
  const DevtasksSessionRepository._();

  /// Returns a list of [DevtasksSession]s matching the given query parameters.
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
  Future<List<DevtasksSession>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksSessionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksSessionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksSessionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DevtasksSession>(
      where: where?.call(DevtasksSession.t),
      orderBy: orderBy?.call(DevtasksSession.t),
      orderByList: orderByList?.call(DevtasksSession.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DevtasksSession] matching the given query parameters.
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
  Future<DevtasksSession?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksSessionTable>? where,
    int? offset,
    _i1.OrderByBuilder<DevtasksSessionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DevtasksSessionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DevtasksSession>(
      where: where?.call(DevtasksSession.t),
      orderBy: orderBy?.call(DevtasksSession.t),
      orderByList: orderByList?.call(DevtasksSession.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DevtasksSession] by its [id] or null if no such row exists.
  Future<DevtasksSession?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DevtasksSession>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DevtasksSession]s in the list and returns the inserted rows.
  ///
  /// The returned [DevtasksSession]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<DevtasksSession>> insert(
    _i1.DatabaseSession session,
    List<DevtasksSession> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<DevtasksSession>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [DevtasksSession] and returns the inserted row.
  ///
  /// The returned [DevtasksSession] will have its `id` field set.
  Future<DevtasksSession> insertRow(
    _i1.DatabaseSession session,
    DevtasksSession row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DevtasksSession>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksSession]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DevtasksSession>> update(
    _i1.DatabaseSession session,
    List<DevtasksSession> rows, {
    _i1.ColumnSelections<DevtasksSessionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DevtasksSession>(
      rows,
      columns: columns?.call(DevtasksSession.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksSession]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DevtasksSession> updateRow(
    _i1.DatabaseSession session,
    DevtasksSession row, {
    _i1.ColumnSelections<DevtasksSessionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DevtasksSession>(
      row,
      columns: columns?.call(DevtasksSession.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DevtasksSession] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DevtasksSession?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<DevtasksSessionUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DevtasksSession>(
      id,
      columnValues: columnValues(DevtasksSession.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DevtasksSession]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DevtasksSession>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<DevtasksSessionUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<DevtasksSessionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DevtasksSessionTable>? orderBy,
    _i1.OrderByListBuilder<DevtasksSessionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DevtasksSession>(
      columnValues: columnValues(DevtasksSession.t.updateTable),
      where: where(DevtasksSession.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DevtasksSession.t),
      orderByList: orderByList?.call(DevtasksSession.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DevtasksSession]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DevtasksSession>> delete(
    _i1.DatabaseSession session,
    List<DevtasksSession> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DevtasksSession>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DevtasksSession].
  Future<DevtasksSession> deleteRow(
    _i1.DatabaseSession session,
    DevtasksSession row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DevtasksSession>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DevtasksSession>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksSessionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DevtasksSession>(
      where: where(DevtasksSession.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<DevtasksSessionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DevtasksSession>(
      where: where?.call(DevtasksSession.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DevtasksSession] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<DevtasksSessionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DevtasksSession>(
      where: where(DevtasksSession.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
