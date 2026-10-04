import 'package:flutter/cupertino.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../errors/app_exception.dart';
import 'app_button.dart';

String localizedErrorMessage(BuildContext context, Object error) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  if (error is AppException) {
    return switch (error.kind) {
      AppFailureKind.configuration => l10n.configurationError,
      AppFailureKind.network || AppFailureKind.timeout => l10n.offlineError,
      _ => l10n.requestFailed,
    };
  }
  return l10n.requestFailed;
}

final class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.error,
    this.onRetry,
    this.title,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(CupertinoIcons.exclamationmark_circle, size: 36),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.errorTitle,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              localizedErrorMessage(context, error),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              AppButton(label: l10n.retry, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
