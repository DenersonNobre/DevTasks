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
import 'dart:async' as _i2;
import 'package:devtasks_client/src/protocol/sign_up_result_dto.dart' as _i3;
import 'package:devtasks_client/src/protocol/sign_up_dto.dart' as _i4;
import 'package:devtasks_client/src/protocol/sign_in_result_dto.dart' as _i5;
import 'package:devtasks_client/src/protocol/sign_in_dto.dart' as _i6;
import 'package:devtasks_client/src/protocol/sign_out_result_dto.dart' as _i7;
import 'package:devtasks_client/src/protocol/me_result_dto.dart' as _i8;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i9;
import 'protocol.dart' as _i10;

/// Endpoint de autenticação (cadastro, login e logout).
///
/// Aplica Object Calisthenics:
/// - 1 nível de indentação por método;
/// - Early-return;
/// - Sem argumentos de token no corpo do signOut (INV-SEC-16).
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  _i2.Future<_i3.SignUpResultDto> signUp(_i4.SignUpDto dto) =>
      caller.callServerEndpoint<_i3.SignUpResultDto>(
        'auth',
        'signUp',
        {'dto': dto},
      );

  _i2.Future<_i5.SignInResultDto> signIn(_i6.SignInDto dto) =>
      caller.callServerEndpoint<_i5.SignInResultDto>(
        'auth',
        'signIn',
        {'dto': dto},
      );

  /// Revoga a sessão ativa do usuário baseando-se estritamente no header `Authorization: Bearer` (INV-SEC-16).
  ///
  /// Proibido aceitar token no corpo do RPC para mitigar vazamento e fixação de sessão.
  /// Operação idempotente que responde com sucesso sem revelar estado.
  _i2.Future<_i7.SignOutResultDto> signOut() =>
      caller.callServerEndpoint<_i7.SignOutResultDto>(
        'auth',
        'signOut',
        {},
      );
}

/// Endpoint privado de referência: exige sessão válida (guard de F1.3).
///
/// O token é lido exclusivamente do header `Authorization: Bearer <token>` (INV-SEC-16).
/// Com `ServerpodSessionService` conectado, o guard valida o token contra a tabela
/// `devtasks_session` rejeitando tokens expirados ou revogados.
/// {@category Endpoint}
class EndpointMe extends _i1.EndpointRef {
  EndpointMe(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'me';

  _i2.Future<_i8.MeResultDto> me() =>
      caller.callServerEndpoint<_i8.MeResultDto>(
        'me',
        'me',
        {},
      );
}

class Modules {
  Modules(Client client) {
    auth = _i9.Caller(client);
  }

  late final _i9.Caller auth;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i10.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    auth = EndpointAuth(this);
    me = EndpointMe(this);
    modules = Modules(this);
  }

  late final EndpointAuth auth;

  late final EndpointMe me;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'me': me,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'auth': modules.auth,
  };
}
