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
import 'package:devtasks_client/src/protocol/project_result_dto.dart' as _i9;
import 'package:devtasks_client/src/protocol/project_list_result_dto.dart'
    as _i10;
import 'package:devtasks_client/src/protocol/workspace_result_dto.dart' as _i11;
import 'package:devtasks_client/src/protocol/workspace_list_result_dto.dart'
    as _i12;
import 'package:devtasks_client/src/protocol/workspace_member_role.dart'
    as _i13;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i14;
import 'protocol.dart' as _i15;

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

/// Endpoint de Projetos (UC-03.01 · F3.1).
///
/// Segurança (Gate 2.5):
/// - Autenticação obrigatória via token de sessão (INV-SEC-16);
/// - Identidade do autor extraída exclusivamente da sessão, nunca do payload (INV-SEC-06);
/// - `INV-01`: não-membro recebe `ERR_NOT_FOUND` indistinguível de inexistente;
/// - `INV-06`: criar/editar exige papel `owner` (via `ProjectService` + `MembershipGuard`).
/// {@category Endpoint}
class EndpointProject extends _i1.EndpointRef {
  EndpointProject(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'project';

  /// Cria um projeto no workspace informado (somente owner).
  _i2.Future<_i9.ProjectResultDto> create(
    int workspaceId,
    String name,
  ) => caller.callServerEndpoint<_i9.ProjectResultDto>(
    'project',
    'create',
    {
      'workspaceId': workspaceId,
      'name': name,
    },
  );

  /// Renomeia um projeto existente (somente owner do workspace do projeto).
  _i2.Future<_i9.ProjectResultDto> update(
    int id,
    String name,
  ) => caller.callServerEndpoint<_i9.ProjectResultDto>(
    'project',
    'update',
    {
      'id': id,
      'name': name,
    },
  );

  /// Lista os projetos ativos do workspace para qualquer membro (INV-01).
  _i2.Future<_i10.ProjectListResultDto> listByWorkspace(int workspaceId) =>
      caller.callServerEndpoint<_i10.ProjectListResultDto>(
        'project',
        'listByWorkspace',
        {'workspaceId': workspaceId},
      );
}

/// Endpoint de gerenciamento de Workspaces (UC-02.01).
///
/// Segurança (Gate 2.5):
/// - Autenticação obrigatória via `SessionAuthenticator` (INV-SEC-16);
/// - Identidade do autor (`userId`) extraída exclusivamente da sessão (INV-SEC-06);
/// - Isolamento multi-tenant: não-membro recebe ERR_NOT_FOUND indistinguível (INV-01);
/// - Autorização por papel: apenas owner muta workspace (INV-06 via `MembershipGuard`).
/// {@category Endpoint}
class EndpointWorkspace extends _i1.EndpointRef {
  EndpointWorkspace(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspace';

  /// Cria um novo workspace e vincula o usuário autenticado como owner.
  _i2.Future<_i11.WorkspaceResultDto> create(String name) =>
      caller.callServerEndpoint<_i11.WorkspaceResultDto>(
        'workspace',
        'create',
        {'name': name},
      );

  /// Renomeia um workspace existente (apenas owner).
  _i2.Future<_i11.WorkspaceResultDto> update(
    int id,
    String name,
  ) => caller.callServerEndpoint<_i11.WorkspaceResultDto>(
    'workspace',
    'update',
    {
      'id': id,
      'name': name,
    },
  );

  /// Lista workspaces pertencentes ao usuário autenticado.
  _i2.Future<_i12.WorkspaceListResultDto> list() =>
      caller.callServerEndpoint<_i12.WorkspaceListResultDto>(
        'workspace',
        'list',
        {},
      );

  /// Consulta detalhes de um workspace específico.
  _i2.Future<_i11.WorkspaceResultDto> getById(int id) =>
      caller.callServerEndpoint<_i11.WorkspaceResultDto>(
        'workspace',
        'getById',
        {'id': id},
      );

  /// Adiciona um membro a um workspace (INV-06 guard aplicado; Gate 2.5).
  _i2.Future<_i11.WorkspaceResultDto> addMember(
    int workspaceId,
    String userId,
    _i13.WorkspaceMemberRole role,
  ) => caller.callServerEndpoint<_i11.WorkspaceResultDto>(
    'workspace',
    'addMember',
    {
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
    },
  );

  /// Remove um membro de um workspace (INV-06 guard aplicado; Gate 2.5).
  _i2.Future<_i11.WorkspaceResultDto> removeMember(
    int workspaceId,
    String userId,
  ) => caller.callServerEndpoint<_i11.WorkspaceResultDto>(
    'workspace',
    'removeMember',
    {
      'workspaceId': workspaceId,
      'userId': userId,
    },
  );
}

class Modules {
  Modules(Client client) {
    auth = _i14.Caller(client);
  }

  late final _i14.Caller auth;
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
         _i15.Protocol(),
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
    project = EndpointProject(this);
    workspace = EndpointWorkspace(this);
    modules = Modules(this);
  }

  late final EndpointAuth auth;

  late final EndpointMe me;

  late final EndpointProject project;

  late final EndpointWorkspace workspace;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'me': me,
    'project': project,
    'workspace': workspace,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'auth': modules.auth,
  };
}
