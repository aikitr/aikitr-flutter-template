import 'package:flutter/cupertino.dart';

import '../../app/localization/generated/app_localizations.dart';

final class AppNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const AppNavigationBar({
    required this.title,
    this.trailing,
    this.previousPageTitle,
    super.key,
  });

  final String title;
  final Widget? trailing;
  final String? previousPageTitle;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) => CupertinoNavigationBar(
    middle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: trailing,
    previousPageTitle: previousPageTitle ?? AppLocalizations.of(context).goBack,
  );
}
