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

abstract class MeDto implements _i1.SerializableModel {
  MeDto._({this.token});

  factory MeDto({String? token}) = _MeDtoImpl;

  factory MeDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return MeDto(token: jsonSerialization['token'] as String?);
  }

  String? token;

  /// Returns a shallow copy of this [MeDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MeDto copyWith({String? token});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MeDto',
      if (token != null) 'token': token,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MeDtoImpl extends MeDto {
  _MeDtoImpl({String? token}) : super._(token: token);

  /// Returns a shallow copy of this [MeDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MeDto copyWith({Object? token = _Undefined}) {
    return MeDto(token: token is String? ? token : this.token);
  }
}
