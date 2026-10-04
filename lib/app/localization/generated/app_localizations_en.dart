// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '__APP_DISPLAY_NAME__';

  @override
  String get loginTitle => 'Welcome';

  @override
  String get loginDescription =>
      'Sign in to explore the reusable app template.';

  @override
  String get authUiRequired =>
      'Replace this screen with the sign-in flow for your identity provider.';

  @override
  String get demoSignIn => 'Continue with demo account';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get articlesTitle => 'Discover';

  @override
  String get articleDetails => 'Article details';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get componentsTitle => 'Component showcase';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get english => 'English';

  @override
  String get chinese => '简体中文';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutMessage => 'You can sign in again whenever you like.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get emptyMessage => 'New items will appear here.';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get offlineError => 'Check your connection and try again.';

  @override
  String get configurationError =>
      'This environment needs its data providers configured before use.';

  @override
  String get detailMissing => 'This item is no longer available.';

  @override
  String get loadMore => 'Load more';

  @override
  String get demoBadge => 'DEMO';

  @override
  String get retrying => 'Retrying…';

  @override
  String get requestFailed => 'The request could not be completed.';

  @override
  String get showComponents => 'Open component showcase';

  @override
  String get formComponents => 'Buttons and forms';

  @override
  String get asyncComponents => 'Async states';

  @override
  String get actionComponents => 'Dialogs and actions';

  @override
  String get paginationComponents => 'Pagination';

  @override
  String get emailPlaceholder => 'Email address';

  @override
  String exampleItem(int number) {
    return 'Example item $number';
  }

  @override
  String get goBack => 'Go back';

  @override
  String get errorDetails => 'Error details';

  @override
  String get refresh => 'Refresh';

  @override
  String pageNumber(int page) {
    return 'Page $page';
  }
}
