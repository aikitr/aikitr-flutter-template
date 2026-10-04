import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_config.dart';
import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_page.dart';
import '../application/session_controller.dart';

final class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppConfig config = ref.watch(appConfigProvider);
    final bool allowDemoLogin =
        config.environment == AppEnvironment.dev && config.allowDemoData;
    final bool isLoading = ref.watch(sessionControllerProvider).isLoading;
    return CupertinoPageScaffold(
      child: SafeArea(
        child: AppPage(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(CupertinoIcons.sparkles, size: 54),
                  const SizedBox(height: 20),
                  Text(
                    l10n.loginTitle,
                    textAlign: TextAlign.center,
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navLargeTitleTextStyle,
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.loginDescription, textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  if (allowDemoLogin) ...<Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemOrange.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          l10n.demoBadge,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      key: const ValueKey<String>('demo-sign-in'),
                      label: isLoading ? l10n.signingIn : l10n.demoSignIn,
                      isLoading: isLoading,
                      onPressed: () =>
                          ref.read(sessionControllerProvider.notifier).signIn(),
                    ),
                  ] else
                    Text(l10n.authUiRequired, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
