import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_view.dart';
import 'app_loading_view.dart';

final class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    required this.value,
    required this.dataBuilder,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) dataBuilder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AsyncData<T>? data = value.asData;
    if (data != null) return dataBuilder(context, data.value);
    if (value.hasError) {
      return AppErrorView(error: value.error!, onRetry: onRetry);
    }
    return const AppLoadingView();
  }
}

final class AppRefreshingView extends StatelessWidget {
  const AppRefreshingView({
    required this.child,
    required this.isRefreshing,
    super.key,
  });

  final Widget child;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      child,
      if (isRefreshing)
        const Positioned(
          top: 4,
          right: 12,
          child: CupertinoActivityIndicator(),
        ),
    ],
  );
}
