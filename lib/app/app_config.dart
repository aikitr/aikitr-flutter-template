import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { dev, staging, prod }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.allowDemoData,
    required this.bundleIdentifier,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool allowDemoData;
  final String bundleIdentifier;

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  factory AppConfig.forEnvironment(
    AppEnvironment environment, {
    required String bundleIdentifier,
  }) {
    return AppConfig(
      environment: environment,
      apiBaseUrl: _apiBaseUrl,
      allowDemoData: environment == AppEnvironment.dev,
      bundleIdentifier: bundleIdentifier,
    );
  }

  String get storageNamespace => '$bundleIdentifier.${environment.name}';
}

final appConfigProvider = Provider<AppConfig>((Ref ref) {
  final String bundleIdentifier = const String.fromEnvironment(
    'APP_BUNDLE_ID',
    defaultValue: '__APP_BUNDLE_ID__',
  );
  return AppConfig.forEnvironment(
    AppEnvironment.dev,
    bundleIdentifier: bundleIdentifier,
  );
});
