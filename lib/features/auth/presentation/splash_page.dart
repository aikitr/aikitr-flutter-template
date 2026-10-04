import 'package:flutter/cupertino.dart';

import '../../../core/ui/app_loading_view.dart';

final class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const CupertinoPageScaffold(child: SafeArea(child: AppLoadingView()));
}
