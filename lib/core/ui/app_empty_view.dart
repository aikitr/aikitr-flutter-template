import 'package:flutter/cupertino.dart';

import '../../app/localization/generated/app_localizations.dart';

final class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, this.title, this.message});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(CupertinoIcons.tray, size: 36),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.emptyTitle,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Text(message ?? l10n.emptyMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
