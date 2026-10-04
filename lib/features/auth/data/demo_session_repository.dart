import 'dart:convert';

import '../../../core/persistence/secure_store.dart';
import '../domain/session.dart';
import '../domain/session_repository.dart';

final class DemoSessionRepository implements SessionRepository {
  const DemoSessionRepository(this._secureStore);

  static const String _sessionKey = 'session';
  final SecureStore _secureStore;

  @override
  Future<Session?> restoreSession() async {
    final String? value = await _secureStore.read(_sessionKey);
    if (value == null) return null;
    try {
      return Session.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } on FormatException {
      await _secureStore.delete(_sessionKey);
      return null;
    } on TypeError {
      await _secureStore.delete(_sessionKey);
      return null;
    }
  }

  @override
  Future<Session> signIn() async {
    final Session session = Session(
      userId: 'demo-user',
      displayName: 'Demo User',
      signedInAt: DateTime.now().toUtc(),
    );
    await _secureStore.write(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  @override
  Future<void> signOut() => _secureStore.delete(_sessionKey);
}
