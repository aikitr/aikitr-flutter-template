import 'package:app_template/core/persistence/secure_store.dart';
import 'package:app_template/features/auth/data/demo_session_repository.dart';
import 'package:app_template/features/auth/domain/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persists a demo session and restores it from secure storage', () async {
    final _MemorySecureStore secureStore = _MemorySecureStore();
    final DemoSessionRepository repository = DemoSessionRepository(secureStore);

    final Session signedIn = await repository.signIn();
    final Session? restored = await DemoSessionRepository(secureStore)
        .restoreSession();

    expect(restored, signedIn);
    expect(signedIn.userId, 'demo-user');
    expect(signedIn.signedInAt.isUtc, isTrue);
  });

  test(
    'discards malformed saved sessions instead of crashing startup',
    () async {
      final _MemorySecureStore secureStore = _MemorySecureStore()
        ..values['session'] = '{bad json';
      final DemoSessionRepository repository = DemoSessionRepository(
        secureStore,
      );

      expect(await repository.restoreSession(), isNull);
      expect(secureStore.values, isEmpty);
    },
  );

  test('discards sessions whose JSON has the wrong shape', () async {
    final _MemorySecureStore secureStore = _MemorySecureStore()
      ..values['session'] = '{"userId":42}';
    final DemoSessionRepository repository = DemoSessionRepository(secureStore);

    expect(await repository.restoreSession(), isNull);
    expect(secureStore.values, isEmpty);
  });

  test('surfaces secure storage write failures during sign in', () async {
    final _MemorySecureStore secureStore = _MemorySecureStore()
      ..writeError = StateError('keychain unavailable');
    final DemoSessionRepository repository = DemoSessionRepository(secureStore);

    await expectLater(repository.signIn(), throwsA(isA<StateError>()));
  });

  test('signing out removes only the session record', () async {
    final _MemorySecureStore secureStore = _MemorySecureStore()
      ..values['locale'] = 'zh';
    final DemoSessionRepository repository = DemoSessionRepository(secureStore);
    await repository.signIn();

    await repository.signOut();

    expect(await repository.restoreSession(), isNull);
    expect(secureStore.values, <String, String>{'locale': 'zh'});
  });
}

final class _MemorySecureStore implements SecureStore {
  final Map<String, String> values = <String, String>{};
  Object? writeError;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (writeError case final Object error) throw error;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}
