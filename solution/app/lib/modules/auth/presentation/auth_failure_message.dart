import 'package:devtasks_app/global/kernel/.kernel.dart';

/// Mensagem de formulário para uma falha esperada.
///
/// Falha de infraestrutura vira texto genérico (DESIGN §3: sem jargão de backend,
/// sem host/timeout na tela); falhas de domínio mantêm a mensagem única do contrato.
String authFailureMessage(IFailure failure) => failure is InfraFailure
    ? 'Não foi possível concluir agora. Tente novamente.'
    : failure.message;
