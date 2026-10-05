import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/persistence/namespaced_secure_store.dart';
import '../data/demo_session_repository.dart';
import '../domain/session.dart';
import '../domain/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  if (!config.allowDemoData) {
    return const _UnconfiguredSessionRepository();
  }
  return DemoSessionRepository(ref.watch(namespacedSecureStoreProvider));
});

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

final authSessionInvalidatedProvider =
    NotifierProvider<AuthSessionInvalidatedController, int>(
      AuthSessionInvalidatedController.new,
    );

final class AuthSessionInvalidatedController extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state++;
}

final class SessionController extends AsyncNotifier<Session?> {
  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  @override
  Future<Session?> build() {
    ref.listen(authSessionInvalidatedProvider, (int? previous, int next) {
      if (previous != null && next != previous && state.value != null) {
        unawaited(signOut());
      }
    });
    return _repository.restoreSession();
  }

  Future<void> signIn() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.signIn());
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(null);
  }
}

final class _UnconfiguredSessionRepository implements SessionRepository {
  const _UnconfiguredSessionRepository();

  AppException _error() => const AppException(
    AppFailureKind.configuration,
    message: 'Configure a SessionRepository for this environment.',
  );

  @override
  Future<Session?> restoreSession() => Future<Session?>.error(_error());

  @override
  Future<Session> signIn() => Future<Session>.error(_error());

  @override
  Future<void> signOut() => Future<void>.error(_error());
}
