import 'session.dart';

abstract interface class SessionRepository {
  Future<Session?> restoreSession();

  Future<Session> signIn();

  Future<void> signOut();
}
