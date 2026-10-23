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
import 'me_result_dto.dart' as _i2;
import 'sign_in_dto.dart' as _i3;
import 'sign_in_result_dto.dart' as _i4;
import 'sign_up_dto.dart' as _i5;
import 'sign_up_result_dto.dart' as _i6;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i7;
export 'me_result_dto.dart';
export 'sign_in_dto.dart';
export 'sign_in_result_dto.dart';
export 'sign_up_dto.dart';
export 'sign_up_result_dto.dart';
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

    if (t == _i2.MeResultDto) {
      return _i2.MeResultDto.fromJson(data) as T;
    }
    if (t == _i3.SignInDto) {
      return _i3.SignInDto.fromJson(data) as T;
    }
    if (t == _i4.SignInResultDto) {
      return _i4.SignInResultDto.fromJson(data) as T;
    }
    if (t == _i5.SignUpDto) {
      return _i5.SignUpDto.fromJson(data) as T;
    }
    if (t == _i6.SignUpResultDto) {
      return _i6.SignUpResultDto.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.MeResultDto?>()) {
      return (data != null ? _i2.MeResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.SignInDto?>()) {
      return (data != null ? _i3.SignInDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.SignInResultDto?>()) {
      return (data != null ? _i4.SignInResultDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.SignUpDto?>()) {
      return (data != null ? _i5.SignUpDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.SignUpResultDto?>()) {
      return (data != null ? _i6.SignUpResultDto.fromJson(data) : null) as T;
    }
    try {
      return _i7.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.MeResultDto => 'MeResultDto',
      _i3.SignInDto => 'SignInDto',
      _i4.SignInResultDto => 'SignInResultDto',
      _i5.SignUpDto => 'SignUpDto',
      _i6.SignUpResultDto => 'SignUpResultDto',
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
      case _i2.MeResultDto():
        return 'MeResultDto';
      case _i3.SignInDto():
        return 'SignInDto';
      case _i4.SignInResultDto():
        return 'SignInResultDto';
      case _i5.SignUpDto():
        return 'SignUpDto';
      case _i6.SignUpResultDto():
        return 'SignUpResultDto';
    }
    className = _i7.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'MeResultDto') {
      return deserialize<_i2.MeResultDto>(data['data']);
    }
    if (dataClassName == 'SignInDto') {
      return deserialize<_i3.SignInDto>(data['data']);
    }
    if (dataClassName == 'SignInResultDto') {
      return deserialize<_i4.SignInResultDto>(data['data']);
    }
    if (dataClassName == 'SignUpDto') {
      return deserialize<_i5.SignUpDto>(data['data']);
    }
    if (dataClassName == 'SignUpResultDto') {
      return deserialize<_i6.SignUpResultDto>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i7.Protocol().deserializeByClassName(data);
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
      return _i7.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
