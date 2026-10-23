import 'package:devtasks_app/global/session/.session.dart';

/// Decisão de navegação para uma rota.
enum RouteDecision { allow, redirectToLogin }

/// Guarda de rotas do app (puro; o roteador real é decisão do slice de UI).
///
/// Rota privada sem sessão ⇒ redireciona ao login; rota pública sempre passa.
class RouteGuard {
  const RouteGuard();

  RouteDecision decide({
    required bool requiresSession,
    required SessionState session,
  }) =>
      requiresSession && !session.isAuthenticated
          ? RouteDecision.redirectToLogin
          : RouteDecision.allow;
}
