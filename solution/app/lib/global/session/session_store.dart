/// Porta de persistência da sessão (DIP).
///
/// A apresentação não conhece o mecanismo de armazenamento: o adaptador real
/// (armazenamento local do dispositivo) entra pela borda e é injetado.
abstract interface class ISessionStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// Alias retrocompatível com a nomenclatura anterior.
typedef SessionStore = ISessionStore;
