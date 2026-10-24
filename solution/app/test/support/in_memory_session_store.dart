import 'package:devtasks_app/global/session/.session.dart';

/// Store em memória: prova o round-trip de sessão sem tocar no dispositivo.
final class InMemorySessionStore implements ISessionStore {
  InMemorySessionStore([this.token]);

  String? token;
  int writes = 0;
  int clears = 0;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
    writes++;
  }

  @override
  Future<void> clear() async {
    token = null;
    clears++;
  }
}
