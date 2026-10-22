// solution/app/lib/global/kernel/clock.dart
// Porta de abstração temporal para testes determinísticos (SPEC §5.1 / INV-07)

/// Porta para obtenção de tempo e data do sistema.
abstract interface class IClock {
  /// Retorna data e hora atuais.
  DateTime now();

  /// Retorna o início do dia corrente (00:00:00).
  DateTime today();
}

/// Implementação padrão que consulta o relógio real do sistema operacional.
class SystemClock implements IClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

