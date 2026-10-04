import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import 'secure_store.dart';

final namespacedSecureStoreProvider = Provider<SecureStore>((Ref ref) {
  final String namespace = ref.watch(appConfigProvider).storageNamespace;
  final SecureStore secureStore = ref.watch(secureStoreProvider);
  return NamespacedSecureStore(secureStore, namespace);
});

final class NamespacedSecureStore implements SecureStore {
  const NamespacedSecureStore(this._store, this._namespace);

  final SecureStore _store;
  final String _namespace;

  String _key(String key) => '$_namespace.$key';

  @override
  Future<String?> read(String key) => _store.read(_key(key));

  @override
  Future<void> write(String key, String value) =>
      _store.write(_key(key), value);

  @override
  Future<void> delete(String key) => _store.delete(_key(key));
}
