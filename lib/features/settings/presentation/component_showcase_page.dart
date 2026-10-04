import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/ui/app_async_view.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_dialogs.dart';
import '../../../core/ui/app_empty_view.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/app_input_field.dart';
import '../../../core/ui/app_loading_view.dart';
import '../../../core/ui/app_navigation_bar.dart';
import '../../../core/ui/app_page.dart';
import '../../../core/ui/app_paginated_list.dart';

final class ComponentShowcasePage extends StatefulWidget {
  const ComponentShowcasePage({super.key});

  @override
  State<ComponentShowcasePage> createState() => _ComponentShowcasePageState();
}

final class _ComponentShowcasePageState extends State<ComponentShowcasePage> {
  final TextEditingController _controller = TextEditingController();
  final List<int> _previewItems = <int>[1, 2, 3];
  bool _isPreviewLoading = false;
  bool _hasPreviewPage = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPreviewPage() async {
    if (_isPreviewLoading || !_hasPreviewPage) return;
    setState(() => _isPreviewLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      final int firstNewItem = _previewItems.length + 1;
      _previewItems.addAll(<int>[firstNewItem, firstNewItem + 1]);
      _isPreviewLoading = false;
      _hasPreviewPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: AppNavigationBar(title: l10n.componentsTitle),
      child: AppPage(
        child: ListView(
          children: <Widget>[
            _Section(
              title: l10n.formComponents,
              child: Column(
                children: <Widget>[
                  AppInputField(
                    controller: _controller,
                    placeholder: l10n.emailPlaceholder,
                  ),
                  const SizedBox(height: 12),
                  AppButton(label: l10n.confirm, onPressed: () {}),
                ],
              ),
            ),
            _Section(
              title: l10n.asyncComponents,
              child: const Column(
                children: <Widget>[
                  SizedBox(height: 72, child: AppLoadingView()),
                  SizedBox(height: 140, child: AppEmptyView()),
                  SizedBox(
                    height: 180,
                    child: AppErrorView(
                      error: AppException(AppFailureKind.network),
                    ),
                  ),
                  _ReadyAsyncExample(),
                ],
              ),
            ),
            _Section(
              title: l10n.actionComponents,
              child: AppButton(
                label: l10n.showComponents,
                onPressed: () => showAppActionSheet(
                  context,
                  title: l10n.componentsTitle,
                  actions: <Widget>[
                    CupertinoActionSheetAction(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.confirm),
                    ),
                  ],
                ),
              ),
            ),
            _Section(
              title: l10n.paginationComponents,
              child: SizedBox(
                height: 240,
                child: AppPaginatedList<int>(
                  items: _previewItems,
                  hasMore: _hasPreviewPage,
                  isLoadingMore: _isPreviewLoading,
                  onLoadMore: _loadPreviewPage,
                  padding: EdgeInsets.zero,
                  itemBuilder: (BuildContext context, int number, int index) =>
                      CupertinoListTile(title: Text(l10n.exampleItem(number))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: CupertinoTheme.of(context).textTheme.textStyle
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        child,
      ],
    ),
  );
}

final class _ReadyAsyncExample extends StatelessWidget {
  const _ReadyAsyncExample();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: AppAsyncView<int>(
      value: const AsyncData<int>(1),
      dataBuilder: (BuildContext context, int data) =>
          Center(child: Text('AsyncValue.data($data)')),
    ),
  );
}
