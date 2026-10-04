import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/app_navigation_bar.dart';
import '../../../core/ui/app_page.dart';
import '../application/session_controller.dart';

final class ConfigurationPage extends ConsumerWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Object error =
        ref.watch(sessionControllerProvider).error ??
        const AppException(
          AppFailureKind.configuration,
          message: 'Configure repositories and API_BASE_URL for this flavor.',
        );
    final bool needsConfiguration =
        error is AppException && error.kind == AppFailureKind.configuration;
    return CupertinoPageScaffold(
      navigationBar: AppNavigationBar(
        title: needsConfiguration ? l10n.configurationError : l10n.errorTitle,
      ),
      child: AppPage(
        child: AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(sessionControllerProvider),
        ),
      ),
    );
  }
}
