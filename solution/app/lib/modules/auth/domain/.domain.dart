// solution/app/lib/modules/auth/domain/.domain.dart
// Barrel pontuado do domínio de autenticação (VOs + portas DIP).
// Vive DENTRO do diretório que agrega (mesma convenção de global/kernel/.kernel.dart),
// logo os caminhos de export são relativos a este diretório.

export 'auth_client.dart' show AuthClient, AuthSession, IAuthClient;
export 'email.dart' show Email;
export 'password.dart' show Password;
