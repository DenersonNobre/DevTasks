import 'package:devtasks_server/src/modules/auth/domain/email.dart';
import 'package:devtasks_server/src/modules/auth/domain/password.dart';
import 'package:test/test.dart';

void main() {
  group('Server Auth Domain VOs (DRY & INV-SEC-08)', () {
    group('Email Value Object', () {
      test('normaliza espaços e caixa', () {
        final result = Email.parse('  USER@Domain.COM ');
        expect(result.error, isNull);
        expect(result.email!.value, 'user@domain.com');
      });

      test('rejeita e-mail vazio ou em branco', () {
        expect(Email.parse('').error, 'E-mail é obrigatório.');
        expect(Email.parse('   ').error, 'E-mail é obrigatório.');
      });

      test('rejeita e-mail malformado sem @ ou sem domínio', () {
        expect(Email.parse('sem-arroba').error, 'E-mail inválido.');
        expect(Email.parse('user@dominio').error, 'E-mail inválido.');
        expect(Email.parse('user@.com').error, 'E-mail inválido.');
      });

      test('compara por valor e mascara toString', () {
        final e1 = Email.parse('a@b.com').email!;
        final e2 = Email.parse('  A@B.COM ').email!;
        expect(e1, equals(e2));
        expect(e1.toString(), 'Email(***)');
      });
    });

    group('Password Value Object & Política de Complexidade', () {
      test('rejeita senhas menores que 12 caracteres', () {
        expect(Password.validate('Curta1!Aa'), 'A senha deve ter ao menos 12 caracteres.');
      });

      test('rejeita senhas maiores que 128 caracteres', () {
        final longPass = 'A1a${'x' * 126}';
        expect(Password.validate(longPass), 'A senha deve ter no máximo 128 caracteres.');
      });

      test('rejeita sem minúscula', () {
        expect(Password.validate('SEMMINUSCULA1!A'), 'A senha deve conter ao menos uma letra minúscula.');
      });

      test('rejeita sem maiúscula', () {
        expect(Password.validate('semmaiuscula1!a'), 'A senha deve conter ao menos uma letra maiúscula.');
      });

      test('rejeita sem dígito', () {
        expect(Password.validate('SemDigitoObrigatorio!'), 'A senha deve conter ao menos um dígito.');
      });

      test('aceita senha válida e mascara toString', () {
        expect(Password.validate('F0rtress!Pass2026'), isNull);
      });
    });
  });
}

