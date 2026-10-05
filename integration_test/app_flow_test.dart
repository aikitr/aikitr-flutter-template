import 'package:app_template/app/localization/generated/app_localizations.dart';
import 'package:app_template/app/app_config.dart';
import 'package:app_template/features/articles/presentation/article_detail_page.dart';
import 'package:app_template/features/articles/presentation/article_list_page.dart';
import 'package:app_template/features/auth/presentation/login_page.dart';
import 'package:app_template/features/settings/presentation/component_showcase_page.dart';
import 'package:app_template/features/settings/presentation/settings_page.dart';
import 'package:app_template/main_dev.dart' as app;
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in, browse, open shared components, and sign out', (
    WidgetTester tester,
  ) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final AppConfig config = AppConfig.forEnvironment(
      AppEnvironment.dev,
      bundleIdentifier: packageInfo.packageName,
    );
    await const FlutterSecureStorage().delete(
      key: '${config.storageNamespace}.session',
    );
    final SharedPreferencesAsync preferences = SharedPreferencesAsync();
    await preferences.remove('theme_mode');
    await preferences.remove('locale');

    await app.main();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('demo-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byType(ArticleListPage), findsOneWidget);

    await tester.tap(find.text('Building a thoughtful iOS app 1'));
    await tester.pumpAndSettle();
    expect(find.byType(ArticleDetailPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.settings).last);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsPage)),
    );
    await tester.tap(find.text(l10n.appearance));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.darkTheme).last);
    await tester.pumpAndSettle();
    expect(await SharedPreferencesAsync().getString('theme_mode'), 'dark');
    expect(find.byType(SettingsPage), findsOneWidget);

    l10n = AppLocalizations.of(tester.element(find.byType(SettingsPage)));
    await tester.tap(find.text(l10n.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.chinese).last);
    await tester.pumpAndSettle();
    expect(await SharedPreferencesAsync().getString('locale'), 'chinese');
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('component-showcase')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ComponentShowcasePage), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoDialogAction).last);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
