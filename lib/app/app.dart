import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import 'app_router.dart';
import 'localization/generated/app_localizations.dart';
import 'theme/app_theme.dart';

final class TemplateApp extends ConsumerWidget {
  const TemplateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings =
        ref.watch(settingsControllerProvider).value ?? const AppSettings();
    final CupertinoThemeData theme = switch (settings.themeMode) {
      AppThemeMode.system => AppTheme.system(),
      AppThemeMode.light => AppTheme.light(),
      AppThemeMode.dark => AppTheme.dark(),
    };
    final Locale? locale = switch (settings.locale) {
      AppLocalePreference.system => null,
      AppLocalePreference.english => const Locale('en'),
      AppLocalePreference.chinese => const Locale('zh'),
    };

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
    );
  }
}
