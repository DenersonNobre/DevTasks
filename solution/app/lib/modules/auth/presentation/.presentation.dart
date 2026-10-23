// solution/app/lib/modules/auth/presentation/.presentation.dart
// Barrel pontuado do estado de apresentação de autenticação (D-07).
// Exporta apenas estados/status: os ViewModels importam este barrel, então
// exportá-los aqui criaria ciclo (um arquivo nunca importa o barrel que o exporta).

export 'auth_form_status.dart' show AuthFormStatus;
export 'login/login_state.dart' show LoginState;
export 'register/register_state.dart' show RegisterState;
