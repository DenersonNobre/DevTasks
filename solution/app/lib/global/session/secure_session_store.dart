import 'session_store.dart';

/// Porta fina para armazenamento seguro de chave-valor (DIP).
///
/// Permite isolar o plugin `flutter_secure_storage` da lógica de negócio e
/// viabilizar testes unitários sem MethodChannels do Flutter.
abstract interface class ISecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Alias retrocompatível com a nomenclatura anterior.
typedef SecureKeyValueStore = ISecureKeyValueStore;

/// Chaves canônicas de armazenamento seguro — sem strings mágicas espalhadas.
abstract final class SessionStorageKeys {
  static const String sessionToken = 'devtasks.session.token';
}

/// Implementação da porta [ISessionStore] sobre [ISecureKeyValueStore].
class SecureSessionStore implements ISessionStore {
  const SecureSessionStore(this._store);

  final ISecureKeyValueStore _store;

  @override
  Future<String?> read() => _store.read(SessionStorageKeys.sessionToken);

  @override
  Future<void> write(String token) =>
      _store.write(SessionStorageKeys.sessionToken, token);

  @override
  Future<void> clear() => _store.delete(SessionStorageKeys.sessionToken);
}

