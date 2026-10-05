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
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
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

Future<T?> showAppActionSheet<T>(
  BuildContext context, {
  required String title,
  required List<Widget> actions,
}) async {
  final CupertinoModalPopupRoute<T> route = CupertinoModalPopupRoute<T>(
    barrierLabel: CupertinoLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: CupertinoDynamicColor.resolve(
      kCupertinoModalBarrierColor,
      context,
    ),
    builder: (BuildContext sheetContext) => CupertinoActionSheet(
      title: Text(title),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: Text(AppLocalizations.of(context).cancel),
      ),
    ),
  );
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  final T? result = await navigator.push(route);
  await route.completed;
  return result;
}
