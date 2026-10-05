import 'package:app_template/app/localization/generated/app_localizations.dart';
import 'package:app_template/core/ui/app_dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('waits for the action sheet dismissal animation', (
    WidgetTester tester,
  ) async {
    bool actionSheetCompleted = false;
    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => CupertinoButton(
            onPressed: () {
              showAppActionSheet(
                context,
                title: 'Choose',
                actions: <Widget>[
                  CupertinoActionSheetAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ).then((_) => actionSheetCompleted = true);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(actionSheetCompleted, isFalse);
    await tester.pumpAndSettle();
    expect(actionSheetCompleted, isTrue);
  });
}
