import 'package:flutter/cupertino.dart';

abstract final class AppTheme {
  static const double pagePadding = 20;
  static const double itemSpacing = 12;
  static const double cardRadius = 16;

  static CupertinoThemeData light() => const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
  );

  static CupertinoThemeData dark() => const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: CupertinoColors.black,
    barBackgroundColor: CupertinoColors.systemBackground,
  );

  static CupertinoThemeData system() => const CupertinoThemeData(
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
  );
}
