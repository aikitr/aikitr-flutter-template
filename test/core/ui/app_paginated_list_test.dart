import 'package:app_template/app/localization/generated/app_localizations.dart';
import 'package:app_template/core/ui/app_paginated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders items and requests another page', (
    WidgetTester tester,
  ) async {
    int loadRequests = 0;

    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CupertinoPageScaffold(
          child: AppPaginatedList<int>(
            items: const <int>[1, 2],
            hasMore: true,
            isLoadingMore: false,
            onLoadMore: () async => loadRequests++,
            itemBuilder: (BuildContext context, int item, int index) =>
                Text('Item $item'),
          ),
        ),
      ),
    );

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Load more'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    expect(loadRequests, 1);
  });
}
