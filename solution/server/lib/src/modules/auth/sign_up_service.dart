import '../../generated/protocol.dart';
import 'ports.dart';
import 'sign_up_handler.dart';

/// Núcleo do cadastro fora do `Endpoint` (testável sem `Session`).
class SignUpService {
  SignUpService([this._handler]);

  final SignUpHandler? _handler;

  Future<SignUpResultDto> signUp(SignUpDto dto) async {
    final handler = _handler;
    if (handler == null) {
      return SignUpResultDto(
        success: false,
        errorCode: SignUpErrorCode.infra.wireCode,
        message: 'Cadastro indisponível no momento.',
      );
    }

    final outcome = await handler.execute(
      SignUpCommand(name: dto.name, email: dto.email, password: dto.password),
    );

    final user = outcome.user;
    if (user != null) {
      return SignUpResultDto(success: true, userId: user.id);
    }

    final failure = outcome.failure!;
    return SignUpResultDto(
      success: false,
      errorCode: failure.code.wireCode,
      message: failure.message,
    );
  }
}
