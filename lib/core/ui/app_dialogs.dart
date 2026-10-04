import 'package:flutter/cupertino.dart';

import '../../app/localization/generated/app_localizations.dart';

Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool destructive = false,
}) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final bool? confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<void> showAppActionSheet(
  BuildContext context, {
  required String title,
  required List<Widget> actions,
}) async {
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext sheetContext) => CupertinoActionSheet(
      title: Text(title),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: Text(AppLocalizations.of(context).cancel),
      ),
    ),
  );
}
