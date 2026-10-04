import 'package:flutter/cupertino.dart';

import '../../app/theme/app_theme.dart';

final class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.pagePadding),
    this.safeArea = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
    return safeArea ? SafeArea(child: content) : content;
  }
}
