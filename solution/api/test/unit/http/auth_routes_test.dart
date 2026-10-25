import 'dart:convert';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FakeUserRepository implements IUserRepository, ICredentialRepository {
  final Map<String, RegisteredUser> usersByEmail = {};
  final Map<String, String> passwordsByEmail = {};
  final Map<String, RegisteredUser> usersById = {};

  @override
  Future<bool> existsByEmail(String normalizedEmail) async =>
      usersByEmail.containsKey(normalizedEmail);

  @override
  Future<CreateUserOutcome> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    if (usersByEmail.containsKey(email)) {
      return const EmailTaken();
    }
    final id = 'user-${usersById.length + 1}';
    final user = RegisteredUser(
      id: id,
      name: name,
      email: email,
      emailVerified: false,
    );
    usersByEmail[email] = user;
    usersById[id] = user;
    passwordsByEmail[email] = passwordHash;
    return UserCreated(user);
  }

  @override
  Future<UserProfile?> findById(String userId) async {
    final user = usersById[userId];
    if (user == null) return null;
    return UserProfile(userId: user.id, name: user.name, email: user.email);
  }

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async {
    final user = usersByEmail[normalizedEmail];
    if (user == null) return null;
    final hash = passwordsByEmail[normalizedEmail]!;
    return CredentialRecord(id: user.id, email: user.email, passwordHash: hash);
  }

  @override
  Future<String?> findEmailById(String userId) async =>
      usersById[userId]?.email;
}

class _FakeSessionRepository implements ISessionRepository {
  final Map<String, SessionRecord> sessions = {};

  @override
  Future<void> save(SessionRecord session) async {
    sessions[session.tokenHash] = session;
  }

  @override
  Future<SessionRecord?> findByTokenHash(String tokenHash) async =>
      sessions[tokenHash];

  @override
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt) async {
    final session = sessions[tokenHash];
    if (session != null) {
      sessions[tokenHash] = SessionRecord(
        userId: session.userId,
        tokenHash: session.tokenHash,
        createdAt: session.createdAt,
        expiresAt: session.expiresAt,
        revokedAt: revokedAt,
      );
    }
  }
}

class _FastPasswordHasher implements IPasswordHasher, IPasswordVerifier {
  @override
  Future<String> hash(String password) async => 'fast-hash:$password';

  @override
  Future<bool> verify({
    required String password,
    required String passwordHash,
  }) async =>
      passwordHash == 'fast-hash:$password';
}

void main() {
  group('AuthRoutes (F8.3 / UC-08.03 / OpenAPI 3.1)', () {
    late _FakeUserRepository userRepo;
    late _FakeSessionRepository sessionRepo;
    late _FastPasswordHasher hasher;
    late SignUpHandler signUpHandler;
    late SignInHandler signInHandler;
    late SessionService sessionService;
    late InMemoryRateLimiter rateLimiter;
    late Handler appHandler;

    Request makeRequest(
      String method,
      String path, {
      Object? body,
      String? token,
    }) {
      final headers = <String, String>{
        if (body != null) 'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };
      return Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    }

    setUp(() {
      userRepo = _FakeUserRepository();
      sessionRepo = _FakeSessionRepository();
      hasher = _FastPasswordHasher();
      signUpHandler = SignUpHandler(userRepo, hasher);
      signInHandler = SignInHandler(userRepo, hasher);
      sessionService = SessionService(
        repository: sessionRepo,
        credentialRepository: userRepo,
      );
      rateLimiter = InMemoryRateLimiter(
        now: DateTime.now,
        maxAttempts: 5,
        window: const Duration(seconds: 60),
      );

      final authRoutes = AuthRoutes(
        signUpHandler: signUpHandler,
        signInHandler: signInHandler,
        sessionService: sessionService,
        userRepository: userRepo,
        rateLimiter: rateLimiter,
      );

      appHandler = buildHandler(authRoutes: authRoutes);
    });

    group('POST /auth/signup', () {
      test('cria usuário com sucesso e devolve 201 com userId', () async {
        final request = makeRequest(
          'POST',
          '/auth/signup',
          body: {
            'name': 'Ana Silva',
            'email': 'ana.silva@example.com',
            'password': 'Password12345',
          },
        );

        final response = await appHandler(request);
        expect(response.statusCode, 201);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['userId'], isNotEmpty);
      });

      test('retorna 400 ERR_VALIDATION quando corpo não é JSON válido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/auth/signup'),
          headers: {'content-type': 'application/json'},
          body: 'invalid json{',
        );

        final response = await appHandler(request);
        expect(response.statusCode, 400);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_VALIDATION');
      });

      test('retorna 400 ERR_VALIDATION quando name é vazio', () async {
        final request = makeRequest(
          'POST',
          '/auth/signup',
          body: {
            'name': '  ',
            'email': 'ana@example.com',
            'password': 'Password12345',
          },
        );

        final response = await appHandler(request);
        expect(response.statusCode, 400);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_VALIDATION');
        expect(json['field'], 'name');
      });

      test('retorna 409 ERR_EMAIL_ALREADY_TAKEN para e-mail duplicado (INV-08)', () async {
        final req1 = makeRequest(
          'POST',
          '/auth/signup',
          body: {
            'name': 'Ana',
            'email': 'duplicado@example.com',
            'password': 'Password12345',
          },
        );
        await appHandler(req1);

        final req2 = makeRequest(
          'POST',
          '/auth/signup',
          body: {
            'name': 'Ana 2',
            'email': 'duplicado@example.com',
            'password': 'Password12345',
          },
        );
        final response = await appHandler(req2);
        expect(response.statusCode, 409);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_EMAIL_ALREADY_TAKEN');
        expect(json['field'], 'email');
      });
    });

    group('POST /auth/signin', () {
      setUp(() async {
        await signUpHandler.execute(
          const SignUpCommand(
            name: 'Carlos',
            email: 'carlos@example.com',
            password: 'Password12345',
          ),
        );
      });

      test('autentica credenciais válidas e devolve 200 com sessionToken', () async {
        final request = makeRequest(
          'POST',
          '/auth/signin',
          body: {
            'email': 'carlos@example.com',
            'password': 'Password12345',
          },
        );

        final response = await appHandler(request);
        expect(response.statusCode, 200);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['sessionToken'], isA<String>());
        expect(json['userId'], isA<String>());
      });

      test('retorna 401 ERR_INVALID_CREDENTIALS para senha errada (INV-SEC-04)', () async {
        final request = makeRequest(
          'POST',
          '/auth/signin',
          body: {
            'email': 'carlos@example.com',
            'password': 'WrongPassword999',
          },
        );

        final response = await appHandler(request);
        expect(response.statusCode, 401);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INVALID_CREDENTIALS');
      });

      test('retorna 401 ERR_INVALID_CREDENTIALS para e-mail inexistente (INV-SEC-04)', () async {
        final request = makeRequest(
          'POST',
          '/auth/signin',
          body: {
            'email': 'inexistente@example.com',
            'password': 'Password12345',
          },
        );

        final response = await appHandler(request);
        expect(response.statusCode, 401);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INVALID_CREDENTIALS');
      });

      test('retorna 429 ERR_RATE_LIMITED quando cota de tentativas estoura (INV-SEC-13)', () async {
        for (var i = 0; i < 5; i++) {
          final req = makeRequest(
            'POST',
            '/auth/signin',
            body: {
              'email': 'carlos@example.com',
              'password': 'WrongPassword999',
            },
          );
          await appHandler(req);
        }

        final throttledReq = makeRequest(
          'POST',
          '/auth/signin',
          body: {
            'email': 'carlos@example.com',
            'password': 'Password12345',
          },
        );
        final response = await appHandler(throttledReq);
        expect(response.statusCode, 429);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_RATE_LIMITED');
        expect(response.headers['retry-after'], isNotNull);
      });

      test('bloqueia tentativas do mesmo IP mesmo alternando e-mails (mitigação B-1 / credential stuffing)', () async {
        for (var i = 0; i < 5; i++) {
          final req = makeRequest(
            'POST',
            '/auth/signin',
            body: {
              'email': 'target_$i@example.com',
              'password': 'WrongPassword999',
            },
          );
          await appHandler(req);
        }

        final throttledReq = makeRequest(
          'POST',
          '/auth/signin',
          body: {
            'email': 'another_target@example.com',
            'password': 'Password12345',
          },
        );
        final response = await appHandler(throttledReq);
        expect(response.statusCode, 429);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_RATE_LIMITED');
      });
    });

    group('POST /auth/signout & GET /me (rotas protegidas)', () {
      late String validToken;
      late String userId;

      setUp(() async {
        final signup = await signUpHandler.execute(
          const SignUpCommand(
            name: 'Maria Souza',
            email: 'maria@example.com',
            password: 'Password12345',
          ),
        );
        userId = signup.user!.id;

        final session = await sessionService.createSession(userId: userId);
        validToken = session.token;
      });

      test('GET /me com token válido devolve perfil do usuário', () async {
        final request = makeRequest('GET', '/me', token: validToken);

        final response = await appHandler(request);
        expect(response.statusCode, 200);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['userId'], userId);
        expect(json['name'], 'Maria Souza');
        expect(json['email'], 'maria@example.com');
      });

      test('GET /me sem token devolve 401 ERR_NOT_AUTHENTICATED', () async {
        final request = makeRequest('GET', '/me');

        final response = await appHandler(request);
        expect(response.statusCode, 401);

        final json = jsonDecode(await response.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_NOT_AUTHENTICATED');
      });

      test('POST /auth/signout revoga o token e subsequente GET /me devolve 401', () async {
        final signoutReq = makeRequest('POST', '/auth/signout', token: validToken);
        final signoutRes = await appHandler(signoutReq);
        expect(signoutRes.statusCode, 200);
        expect(await signoutRes.readAsString(), '{}');

        final meReq = makeRequest('GET', '/me', token: validToken);
        final meRes = await appHandler(meReq);
        expect(meRes.statusCode, 401);
      });
    });
  });
}

