import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/articles/presentation/article_detail_page.dart';
import '../features/articles/presentation/article_list_page.dart';
import '../features/auth/application/session_controller.dart';
import '../features/auth/domain/session.dart';
import '../features/auth/presentation/configuration_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/settings/presentation/component_showcase_page.dart';
import '../features/settings/presentation/main_shell.dart';
import '../features/settings/presentation/settings_page.dart';

abstract final class AppRoutes {
  static const String root = '/';
  static const String splash = '/splash';
  static const String configuration = '/configuration';
  static const String login = '/login';
  static const String articles = '/articles';
  static const String settings = '/settings';
  static const String components = '/settings/components';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _articlesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'articles');
final GlobalKey<NavigatorState> _settingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final _RouterRefresh refresh = _RouterRefresh();
  ref.listen<AsyncValue<Session?>>(sessionControllerProvider, (_, _) {
    refresh.refresh();
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.uri.path;
      final AsyncValue<Session?> sessionState = ref.read(
        sessionControllerProvider,
      );
      if (sessionState.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (sessionState.hasError) {
        return location == AppRoutes.configuration
            ? null
            : AppRoutes.configuration;
      }

      final Session? session = sessionState.value;
      if (location == AppRoutes.splash) {
        return session == null ? AppRoutes.login : AppRoutes.articles;
      }
      if (session == null) {
        if (location == AppRoutes.login ||
            location == AppRoutes.configuration) {
          return null;
        }
        return '${AppRoutes.login}?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (location == AppRoutes.login) {
        return _safeReturnLocation(state.uri.queryParameters['from']) ??
            AppRoutes.articles;
      }
      return location == AppRoutes.root ? AppRoutes.articles : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.configuration,
        builder: (BuildContext context, GoRouterState state) =>
            const ConfigurationPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      GoRoute(path: AppRoutes.root, redirect: (_, _) => AppRoutes.articles),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _articlesNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.articles,
                builder: (BuildContext context, GoRouterState state) =>
                    const ArticleListPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':articleId',
                    builder: (BuildContext context, GoRouterState state) =>
                        ArticleDetailPage(
                          articleId: state.pathParameters['articleId']!,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'components',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ComponentShowcasePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String? _safeReturnLocation(String? candidate) {
  if (candidate == null ||
      !candidate.startsWith('/') ||
      candidate.startsWith('//')) {
    return null;
  }
  final Uri? uri = Uri.tryParse(candidate);
  if (uri == null || uri.hasAuthority || uri.hasScheme) return null;
  if (uri.path == AppRoutes.login || uri.path == AppRoutes.configuration) {
    return null;
  }
  return uri.toString();
}

final class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
