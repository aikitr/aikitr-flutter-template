import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';

final class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          Expanded(child: navigationShell),
          CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (int index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.square_grid_2x2),
                label: l10n.articlesTitle,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.settings),
                label: l10n.settingsTitle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
