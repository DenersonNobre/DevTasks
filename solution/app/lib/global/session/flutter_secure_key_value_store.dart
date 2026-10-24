import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_session_store.dart';

/// Adaptador real que implementa [ISecureKeyValueStore] usando [FlutterSecureStorage].
class FlutterSecureKeyValueStore implements ISecureKeyValueStore {
  const FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

