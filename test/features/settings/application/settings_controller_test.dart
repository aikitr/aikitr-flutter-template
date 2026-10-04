import 'package:app_template/core/persistence/preferences_repository.dart';
import 'package:app_template/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores saved appearance and persists subsequent changes', () async {
    final _MemoryPreferencesRepository preferences =
        _MemoryPreferencesRepository(<String, String>{
          'theme_mode': 'dark',
          'locale': 'chinese',
        });
    final ProviderContainer container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    final AppSettings restored = await container.read(
      settingsControllerProvider.future,
    );
    await container
        .read(settingsControllerProvider.notifier)
        .setThemeMode(AppThemeMode.light);

    expect(restored.themeMode, AppThemeMode.dark);
    expect(restored.locale, AppLocalePreference.chinese);
    expect(preferences.values['theme_mode'], 'light');
    expect(
      container.read(settingsControllerProvider).requireValue.themeMode,
      AppThemeMode.light,
    );
  });

  test('falls back safely when a saved setting is unknown', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          _MemoryPreferencesRepository(<String, String>{
            'theme_mode': 'not-a-theme',
            'locale': 'xx',
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    final AppSettings restored = await container.read(
      settingsControllerProvider.future,
    );

    expect(restored.themeMode, AppThemeMode.system);
    expect(restored.locale, AppLocalePreference.system);
  });

  test('does not update visible settings when storage writes fail', () async {
    final _MemoryPreferencesRepository preferences =
        _MemoryPreferencesRepository(<String, String>{})
          ..writeError = StateError('preferences unavailable');
    final ProviderContainer container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await container.read(settingsControllerProvider.future);

    await expectLater(
      container
          .read(settingsControllerProvider.notifier)
          .setThemeMode(AppThemeMode.dark),
      throwsA(isA<StateError>()),
    );
    expect(
      container.read(settingsControllerProvider).requireValue.themeMode,
      AppThemeMode.system,
    );
  });
}

final class _MemoryPreferencesRepository implements PreferencesRepository {
  _MemoryPreferencesRepository(this.values);

  final Map<String, String> values;
  Object? writeError;

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeString(String key, String value) async {
    if (writeError case final Object error) throw error;
    values[key] = value;
  }
}
