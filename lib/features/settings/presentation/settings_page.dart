import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/app_router.dart';
import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/ui/app_async_view.dart';
import '../../../core/ui/app_dialogs.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/app_navigation_bar.dart';
import '../../../features/auth/application/session_controller.dart';
import '../application/settings_controller.dart';

final class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final AppConfig config = ref.watch(appConfigProvider);
    return CupertinoPageScaffold(
      navigationBar: AppNavigationBar(title: l10n.settingsTitle),
      child: SafeArea(
        child: AppAsyncView<AppSettings>(
          value: settings,
          onRetry: () => ref.invalidate(settingsControllerProvider),
          dataBuilder: (BuildContext context, AppSettings current) => ListView(
            children: <Widget>[
              CupertinoListSection.insetGrouped(
                header: Text(config.environment.name.toUpperCase()),
                children: <Widget>[
                  CupertinoListTile(
                    title: Text(l10n.appearance),
                    additionalInfo: Text(_themeLabel(l10n, current.themeMode)),
                    onTap: () => _chooseTheme(context, ref, current.themeMode),
                  ),
                  CupertinoListTile(
                    title: Text(l10n.language),
                    additionalInfo: Text(_localeLabel(l10n, current.locale)),
                    onTap: () => _chooseLocale(context, ref, current.locale),
                  ),
                  CupertinoListTile(
                    key: const ValueKey<String>('component-showcase'),
                    title: Text(l10n.showComponents),
                    leading: const Icon(CupertinoIcons.square_grid_2x2),
                    onTap: () => context.go(AppRoutes.components),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                children: <Widget>[
                  CupertinoListTile(
                    key: const ValueKey<String>('sign-out'),
                    title: Text(
                      l10n.signOut,
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                    leading: const Icon(
                      CupertinoIcons.square_arrow_left,
                      color: CupertinoColors.destructiveRed,
                    ),
                    onTap: () => _signOut(context, ref, l10n),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, AppThemeMode mode) =>
      switch (mode) {
        AppThemeMode.system => l10n.systemTheme,
        AppThemeMode.light => l10n.lightTheme,
        AppThemeMode.dark => l10n.darkTheme,
      };

  String _localeLabel(AppLocalizations l10n, AppLocalePreference locale) =>
      switch (locale) {
        AppLocalePreference.system => l10n.systemTheme,
        AppLocalePreference.english => l10n.english,
        AppLocalePreference.chinese => l10n.chinese,
      };

  Future<void> _chooseTheme(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode selected,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppThemeMode? mode = await showAppActionSheet<AppThemeMode>(
      context,
      title: l10n.appearance,
      actions: AppThemeMode.values
          .map(
            (AppThemeMode mode) => CupertinoActionSheetAction(
              isDefaultAction: mode == selected,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(mode),
              child: Text(_themeLabel(l10n, mode)),
            ),
          )
          .toList(growable: false),
    );
    if (mode == null || !context.mounted) return;
    await _saveSetting(
      context,
      l10n,
      () => ref.read(settingsControllerProvider.notifier).setThemeMode(mode),
    );
  }

  Future<void> _chooseLocale(
    BuildContext context,
    WidgetRef ref,
    AppLocalePreference selected,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppLocalePreference? locale =
        await showAppActionSheet<AppLocalePreference>(
          context,
          title: l10n.language,
          actions: AppLocalePreference.values
              .map(
                (AppLocalePreference locale) => CupertinoActionSheetAction(
                  isDefaultAction: locale == selected,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(locale),
                  child: Text(_localeLabel(l10n, locale)),
                ),
              )
              .toList(growable: false),
        );
    if (locale == null || !context.mounted) return;
    await _saveSetting(
      context,
      l10n,
      () => ref.read(settingsControllerProvider.notifier).setLocale(locale),
    );
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final bool confirm = await showAppConfirmationDialog(
      context,
      title: l10n.signOutTitle,
      message: l10n.signOutMessage,
      destructive: true,
    );
    if (!confirm || !context.mounted) return;
    try {
      await ref.read(sessionControllerProvider.notifier).signOut();
    } on Object catch (error) {
      if (!context.mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.errorTitle),
          content: Text(localizedErrorMessage(context, error)),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveSetting(
    BuildContext context,
    AppLocalizations l10n,
    Future<void> Function() save,
  ) async {
    try {
      await save();
    } on Object catch (error) {
      if (!context.mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.errorTitle),
          content: Text(localizedErrorMessage(context, error)),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
    }
  }
}
