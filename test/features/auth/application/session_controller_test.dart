import 'package:app_template/features/auth/application/session_controller.dart';
import 'package:app_template/features/auth/domain/session.dart';
import 'package:app_template/features/auth/domain/session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clears the active session when the API signals a 401', () async {
    final _FakeSessionRepository repository = _FakeSessionRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final Session? restored = await container.read(
      sessionControllerProvider.future,
    );
    expect(restored, isNotNull);

    container.read(authSessionInvalidatedProvider.notifier).signal();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(sessionControllerProvider).requireValue, isNull);
    expect(repository.signOutCalls, 1);
  });
}

final class _FakeSessionRepository implements SessionRepository {
  int signOutCalls = 0;

  @override
  Future<Session?> restoreSession() async => Session(
    userId: 'user-1',
    displayName: 'User',
    signedInAt: DateTime.utc(2026),
  );

  @override
  Future<Session> signIn() => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
