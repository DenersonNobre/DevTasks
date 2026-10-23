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

abstract class MeResultDto implements _i1.SerializableModel {
  MeResultDto._({
    required this.success,
    this.userId,
    this.email,
    this.errorCode,
    this.message,
  });

  factory MeResultDto({
    required bool success,
    String? userId,
    String? email,
    String? errorCode,
    String? message,
  }) = _MeResultDtoImpl;

  factory MeResultDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return MeResultDto(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      userId: jsonSerialization['userId'] as String?,
      email: jsonSerialization['email'] as String?,
      errorCode: jsonSerialization['errorCode'] as String?,
      message: jsonSerialization['message'] as String?,
    );
  }

  bool success;

  String? userId;

  String? email;

  String? errorCode;

  String? message;

  /// Returns a shallow copy of this [MeResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MeResultDto copyWith({
    bool? success,
    String? userId,
    String? email,
    String? errorCode,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MeResultDto',
      'success': success,
      if (userId != null) 'userId': userId,
      if (email != null) 'email': email,
      if (errorCode != null) 'errorCode': errorCode,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MeResultDtoImpl extends MeResultDto {
  _MeResultDtoImpl({
    required bool success,
    String? userId,
    String? email,
    String? errorCode,
    String? message,
  }) : super._(
         success: success,
         userId: userId,
         email: email,
         errorCode: errorCode,
         message: message,
       );

  /// Returns a shallow copy of this [MeResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MeResultDto copyWith({
    bool? success,
    Object? userId = _Undefined,
    Object? email = _Undefined,
    Object? errorCode = _Undefined,
    Object? message = _Undefined,
  }) {
    return MeResultDto(
      success: success ?? this.success,
      userId: userId is String? ? userId : this.userId,
      email: email is String? ? email : this.email,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      message: message is String? ? message : this.message,
    );
  }
}
