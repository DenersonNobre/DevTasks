/// Estados de um formulário de autenticação (DESIGN §3).
///
/// [completed] é terminal e significa "caso de uso concluído": no login a sessão
/// foi persistida; no cadastro a conta foi criada (o contrato não emite token).
enum AuthFormStatus { idle, loading, error, completed }
