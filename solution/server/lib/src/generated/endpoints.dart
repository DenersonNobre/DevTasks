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
import '../endpoints/auth_endpoint.dart' as _i2;
import '../endpoints/me_endpoint.dart' as _i3;
import '../endpoints/project_endpoint.dart' as _i4;
import '../endpoints/workspace_endpoint.dart' as _i5;
import 'package:devtasks_server/src/generated/sign_up_dto.dart' as _i6;
import 'package:devtasks_server/src/generated/sign_in_dto.dart' as _i7;
import 'package:devtasks_server/src/generated/workspace_member_role.dart'
    as _i8;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i9;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'auth': _i2.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'me': _i3.MeEndpoint()
        ..initialize(
          server,
          'me',
          null,
        ),
      'project': _i4.ProjectEndpoint()
        ..initialize(
          server,
          'project',
          null,
        ),
      'workspace': _i5.WorkspaceEndpoint()
        ..initialize(
          server,
          'workspace',
          null,
        ),
    };
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'signUp': _i1.MethodConnector(
          name: 'signUp',
          params: {
            'dto': _i1.ParameterDescription(
              name: 'dto',
              type: _i1.getType<_i6.SignUpDto>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).signUp(
                session,
                params['dto'],
              ),
        ),
        'signIn': _i1.MethodConnector(
          name: 'signIn',
          params: {
            'dto': _i1.ParameterDescription(
              name: 'dto',
              type: _i1.getType<_i7.SignInDto>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i2.AuthEndpoint).signIn(
                session,
                params['dto'],
              ),
        ),
        'signOut': _i1.MethodConnector(
          name: 'signOut',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).signOut(session),
        ),
      },
    );
    connectors['me'] = _i1.EndpointConnector(
      name: 'me',
      endpoint: endpoints['me']!,
      methodConnectors: {
        'me': _i1.MethodConnector(
          name: 'me',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['me'] as _i3.MeEndpoint).me(session),
        ),
      },
    );
    connectors['project'] = _i1.EndpointConnector(
      name: 'project',
      endpoint: endpoints['project']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i4.ProjectEndpoint).create(
                session,
                params['workspaceId'],
                params['name'],
              ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _i4.ProjectEndpoint).update(
                session,
                params['id'],
                params['name'],
              ),
        ),
        'listByWorkspace': _i1.MethodConnector(
          name: 'listByWorkspace',
          params: {
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _i4.ProjectEndpoint).listByWorkspace(
                    session,
                    params['workspaceId'],
                  ),
        ),
      },
    );
    connectors['workspace'] = _i1.EndpointConnector(
      name: 'workspace',
      endpoint: endpoints['workspace']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspace'] as _i5.WorkspaceEndpoint).create(
                    session,
                    params['name'],
                  ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspace'] as _i5.WorkspaceEndpoint).update(
                    session,
                    params['id'],
                    params['name'],
                  ),
        ),
        'list': _i1.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i5.WorkspaceEndpoint).list(
                session,
              ),
        ),
        'getById': _i1.MethodConnector(
          name: 'getById',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspace'] as _i5.WorkspaceEndpoint).getById(
                    session,
                    params['id'],
                  ),
        ),
        'addMember': _i1.MethodConnector(
          name: 'addMember',
          params: {
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<_i8.WorkspaceMemberRole>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['workspace'] as _i5.WorkspaceEndpoint).addMember(
                    session,
                    params['workspaceId'],
                    params['userId'],
                    params['role'],
                  ),
        ),
        'removeMember': _i1.MethodConnector(
          name: 'removeMember',
          params: {
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i5.WorkspaceEndpoint)
                  .removeMember(
                    session,
                    params['workspaceId'],
                    params['userId'],
                  ),
        ),
      },
    );
    modules['serverpod_auth'] = _i9.Endpoints()..initializeEndpoints(server);
  }
}
