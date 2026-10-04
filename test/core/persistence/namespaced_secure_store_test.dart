import 'package:app_template/core/persistence/namespaced_secure_store.dart';
import 'package:app_template/core/persistence/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'prefixes secure items with the app and environment namespace',
    () async {
      final _MemorySecureStore delegate = _MemorySecureStore();
      final NamespacedSecureStore store = NamespacedSecureStore(
        delegate,
        'com.example.weather.dev',
      );

      await store.write('session', 'demo');

      expect(delegate.values, <String, String>{
        'com.example.weather.dev.session': 'demo',
      });
      expect(await store.read('session'), 'demo');
    },
  );
}

final class _MemorySecureStore implements SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
