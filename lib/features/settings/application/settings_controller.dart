import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/persistence/preferences_repository.dart';

enum AppThemeMode { system, light, dark }

enum AppLocalePreference { system, english, chinese }

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (Ref ref) => SharedPreferencesRepository(SharedPreferencesAsync()),
);

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocalePreference.system,
  });

  final AppThemeMode themeMode;
  final AppLocalePreference locale;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLocalePreference? locale,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
  );
}

final class SettingsController extends AsyncNotifier<AppSettings> {
  PreferencesRepository get _repository =>
      ref.read(preferencesRepositoryProvider);

  @override
  Future<AppSettings> build() async {
    final PreferencesRepository repository = _repository;
    final String? savedTheme = await repository.readString('theme_mode');
    final String? savedLocale = await repository.readString('locale');
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (AppThemeMode value) => value.name == savedTheme,
        orElse: () => AppThemeMode.system,
      ),
      locale: AppLocalePreference.values.firstWhere(
        (AppLocalePreference value) => value.name == savedLocale,
        orElse: () => AppLocalePreference.system,
      ),
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _repository.writeString('theme_mode', mode.name);
    state = AsyncData(
      (state.value ?? const AppSettings()).copyWith(themeMode: mode),
    );
  }

  Future<void> setLocale(AppLocalePreference locale) async {
    await _repository.writeString('locale', locale.name);
    state = AsyncData(
      (state.value ?? const AppSettings()).copyWith(locale: locale),
    );
  }
}
