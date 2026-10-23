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

abstract class SignInDto
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SignInDto._({
    required this.email,
    required this.password,
  });

  factory SignInDto({
    required String email,
    required String password,
  }) = _SignInDtoImpl;

  factory SignInDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return SignInDto(
      email: jsonSerialization['email'] as String,
      password: jsonSerialization['password'] as String,
    );
  }

  String email;

  String password;

  /// Returns a shallow copy of this [SignInDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SignInDto copyWith({
    String? email,
    String? password,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SignInDto',
      'email': email,
      'password': password,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SignInDto',
      'email': email,
      'password': password,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SignInDtoImpl extends SignInDto {
  _SignInDtoImpl({
    required String email,
    required String password,
  }) : super._(
         email: email,
         password: password,
       );

  /// Returns a shallow copy of this [SignInDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SignInDto copyWith({
    String? email,
    String? password,
  }) {
    return SignInDto(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
