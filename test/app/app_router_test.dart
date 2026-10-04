import 'package:app_template/app/app.dart';
import 'package:app_template/app/app_config.dart';
import 'package:app_template/app/localization/generated/app_localizations.dart';
import 'package:app_template/core/persistence/preferences_repository.dart';
import 'package:app_template/core/persistence/secure_store.dart';
import 'package:app_template/features/articles/presentation/article_list_page.dart';
import 'package:app_template/features/auth/application/session_controller.dart';
import 'package:app_template/features/auth/presentation/configuration_page.dart';
import 'package:app_template/features/auth/domain/session.dart';
import 'package:app_template/features/auth/domain/session_repository.dart';
import 'package:app_template/features/auth/presentation/login_page.dart';
import 'package:app_template/features/settings/application/settings_controller.dart';
import 'package:app_template/features/settings/presentation/settings_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'requires a session, opens the app, and returns to login on sign out',
    (WidgetTester tester) async {
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(ArticleListPage), findsNothing);
      await tester.tap(find.byKey(const ValueKey<String>('demo-sign-in')));
      await tester.pumpAndSettle();

      expect(find.byType(ArticleListPage), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.settings).last);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('sign-out')));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      await tester.tap(find.byType(CupertinoDialogAction).last);
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    },
  );

  testWidgets(
    'shows setup guidance when a non-demo environment lacks services',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(environment: AppEnvironment.staging, allowDemoData: false),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConfigurationPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    },
  );

  testWidgets('never shows demo login in a configured non-demo environment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        environment: AppEnvironment.staging,
        allowDemoData: false,
        sessionRepository: _MemorySessionRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('demo-sign-in')), findsNothing);
    expect(find.text('DEMO'), findsNothing);
    expect(
      find.text(
        'Replace this screen with the sign-in flow for your identity provider.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a general error when secure storage cannot restore', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(secureStore: _FailingSecureStore()));
    await tester.pumpAndSettle();

    expect(find.byType(ConfigurationPage), findsOneWidget);
    expect(find.text('The request could not be completed.'), findsOneWidget);
    expect(
      find.text(
        'This environment needs its data providers configured before use.',
      ),
      findsNothing,
    );
  });

  testWidgets('shows an error when saving a setting fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(preferencesRepository: _FailingPreferencesRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('demo-sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.settings).last);
    await tester.pumpAndSettle();
    final BuildContext context = tester.element(find.byType(SettingsPage));
    final AppLocalizations l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.appearance));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.darkTheme));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.text(l10n.requestFailed), findsOneWidget);
  });
}

Widget _testApp({
  AppEnvironment environment = AppEnvironment.dev,
  bool allowDemoData = true,
  SecureStore? secureStore,
  PreferencesRepository? preferencesRepository,
  SessionRepository? sessionRepository,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig(
        environment: environment,
        apiBaseUrl: '',
        allowDemoData: allowDemoData,
        bundleIdentifier: 'com.example.template.${environment.name}',
      ),
    ),
    secureStoreProvider.overrideWithValue(secureStore ?? _MemorySecureStore()),
    if (sessionRepository != null)
      sessionRepositoryProvider.overrideWithValue(sessionRepository),
    preferencesRepositoryProvider.overrideWithValue(
      preferencesRepository ?? _MemoryPreferencesRepository(),
    ),
  ],
  child: const TemplateApp(),
);

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

final class _MemorySessionRepository implements SessionRepository {
  @override
  Future<Session?> restoreSession() async => null;

  @override
  Future<Session> signIn() async => Session(
    userId: 'user-1',
    displayName: 'Test User',
    signedInAt: DateTime.utc(2026),
  );

  @override
  Future<void> signOut() async {}
}

final class _FailingSecureStore implements SecureStore {
  @override
  Future<String?> read(String key) async =>
      throw StateError('keychain is unavailable');

  @override
  Future<void> write(String key, String value) async {
    throw StateError('keychain is unavailable');
  }

  @override
  Future<void> delete(String key) async {
    throw StateError('keychain is unavailable');
  }
}

final class _MemoryPreferencesRepository implements PreferencesRepository {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}

final class _FailingPreferencesRepository implements PreferencesRepository {
  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> writeString(String key, String value) async {
    throw StateError('preferences are unavailable');
  }
}
