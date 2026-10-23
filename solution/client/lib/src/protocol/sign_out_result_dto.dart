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

abstract class SignOutResultDto implements _i1.SerializableModel {
  SignOutResultDto._({
    required this.success,
    this.errorCode,
    this.message,
  });

  factory SignOutResultDto({
    required bool success,
    String? errorCode,
    String? message,
  }) = _SignOutResultDtoImpl;

  factory SignOutResultDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return SignOutResultDto(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      errorCode: jsonSerialization['errorCode'] as String?,
      message: jsonSerialization['message'] as String?,
    );
  }

  bool success;

  String? errorCode;

  String? message;

  /// Returns a shallow copy of this [SignOutResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SignOutResultDto copyWith({
    bool? success,
    String? errorCode,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SignOutResultDto',
      'success': success,
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

class _SignOutResultDtoImpl extends SignOutResultDto {
  _SignOutResultDtoImpl({
    required bool success,
    String? errorCode,
    String? message,
  }) : super._(
         success: success,
         errorCode: errorCode,
         message: message,
       );

  /// Returns a shallow copy of this [SignOutResultDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SignOutResultDto copyWith({
    bool? success,
    Object? errorCode = _Undefined,
    Object? message = _Undefined,
  }) {
    return SignOutResultDto(
      success: success ?? this.success,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      message: message is String? ? message : this.message,
    );
  }
}
