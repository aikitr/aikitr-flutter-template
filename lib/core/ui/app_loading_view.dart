import 'package:flutter/cupertino.dart';

import '../../app/localization/generated/app_localizations.dart';

final class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CupertinoActivityIndicator(radius: 14),
        const SizedBox(height: 12),
        Text(label ?? AppLocalizations.of(context).loading),
      ],
    ),
  );
}
