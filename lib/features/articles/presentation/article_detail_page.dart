import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/ui/app_async_view.dart';
import '../../../core/ui/app_empty_view.dart';
import '../../../core/ui/app_navigation_bar.dart';
import '../../../core/ui/app_page.dart';
import '../application/article_providers.dart';
import '../domain/article.dart';

final class ArticleDetailPage extends ConsumerWidget {
  const ArticleDetailPage({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final detail = ref.watch(articleDetailProvider(articleId));
    return CupertinoPageScaffold(
      navigationBar: AppNavigationBar(title: l10n.articleDetails),
      child: SafeArea(
        child: AppAsyncView<Article?>(
          value: detail,
          onRetry: () => ref.invalidate(articleDetailProvider(articleId)),
          dataBuilder: (BuildContext context, Article? article) {
            if (article == null) {
              return AppEmptyView(message: l10n.detailMissing);
            }
            return AppPage(
              child: ListView(
                children: <Widget>[
                  Text(
                    article.title,
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navLargeTitleTextStyle,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    article.author,
                    style: const TextStyle(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(article.body),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
