// solution/app/lib/modules/auth/.auth.dart
// Barrel pontuado do módulo de autenticação (superfície pública do módulo).
// Regra: um arquivo nunca importa o barrel que o exporta (evita ciclo).

export 'domain/.domain.dart';
export 'infrastructure/.infrastructure.dart';
export 'presentation/.presentation.dart';
export 'presentation/login/login_view.dart' show LoginView;
export 'presentation/login/login_view_model.dart'
    show LoginViewModel, loginViewModelProvider;
export 'presentation/register/register_view.dart' show RegisterView;
export 'presentation/register/register_view_model.dart'
    show RegisterViewModel, registerViewModelProvider;
