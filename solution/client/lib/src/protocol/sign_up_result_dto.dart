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

abstract class SignUpResultDto implements _i1.SerializableModel {
  SignUpResultDto._({
    required this.success,
    this.userId,
    this.errorCode,
    this.message,
    this.field,
  });

  factory SignUpResultDto({
    required bool success,
    String? userId,
    String? errorCode,
    String? message,
    String? field,
  }) = _SignUpResultDtoImpl;

  factory SignUpResultDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return SignUpResultDto(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      userId: jsonSerialization['userId'] as String?,
      errorCode: jsonSerialization['errorCode'] as String?,
      message: jsonSerialization['message'] as String?,
      field: jsonSerialization['field'] as String?,
    );
  }

  bool success;

  String? userId;

  String? errorCode;

  String? message;

  String? field;

  /// Returns a shallow copy of this [SignUpResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SignUpResultDto copyWith({
    bool? success,
    String? userId,
    String? errorCode,
    String? message,
    String? field,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SignUpResultDto',
      'success': success,
      if (userId != null) 'userId': userId,
      if (errorCode != null) 'errorCode': errorCode,
      if (message != null) 'message': message,
      if (field != null) 'field': field,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SignUpResultDtoImpl extends SignUpResultDto {
  _SignUpResultDtoImpl({
    required bool success,
    String? userId,
    String? errorCode,
    String? message,
    String? field,
  }) : super._(
         success: success,
         userId: userId,
         errorCode: errorCode,
         message: message,
         field: field,
       );

  /// Returns a shallow copy of this [SignUpResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SignUpResultDto copyWith({
    bool? success,
    Object? userId = _Undefined,
    Object? errorCode = _Undefined,
    Object? message = _Undefined,
    Object? field = _Undefined,
  }) {
    return SignUpResultDto(
      success: success ?? this.success,
      userId: userId is String? ? userId : this.userId,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      message: message is String? ? message : this.message,
      field: field is String? ? field : this.field,
    );
  }
}
